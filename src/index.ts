import type { EventSubscription } from "expo-modules-core";

import { getNativeVungleModule } from "./NativeVungle";
import { setJsLoggingEnabled, vungleLog } from "./logger";
import type { VungleInitOptions, VungleNativeEvent, VungleRewardedLoadOptions } from "./types";

export type { VungleEventKind, VungleInitOptions, VungleNativeEvent, VungleRewardedLoadOptions } from "./types";
export { isJsLoggingEnabled, setJsLoggingEnabled, vungleLog } from "./logger";

function native() {
  return getNativeVungleModule();
}

/**
 * Initialize the Liftoff Monetize (Vungle) SDK. Call once before loading ads.
 */
export async function initVungle(options: VungleInitOptions): Promise<boolean> {
  const logging = options.loggingEnabled ?? (typeof __DEV__ !== "undefined" ? __DEV__ : false);
  vungleLog.info("initVungle_start", `appIdLength=${options.appId.length} loggingEnabled=${String(logging)}`);
  setJsLoggingEnabled(logging);
  native().setLoggingEnabled(logging);
  try {
    const ok = await native().initSdkAsync(options.appId, logging);
    vungleLog.info("initVungle_complete", String(ok));
    return ok;
  } catch (e) {
    vungleLog.error("initVungle_failed", e instanceof Error ? e.message : String(e));
    throw e;
  }
}

export function getSdkVersion(): string {
  const v = native().getSdkVersionSync();
  vungleLog.debug("getSdkVersion", v);
  return v;
}

/**
 * Liftoff bidding token for programmatic / header bidding (Android).
 * Send the token to your exchange or server auction; use the returned bid response as `adMarkup` in {@link VungleRewardedAd.load}.
 * On iOS this rejects with `ERR_VUNGLE_BIDDING_ANDROID_ONLY`.
 */
export async function getVungleBiddingToken(): Promise<string> {
  vungleLog.info("getVungleBiddingToken_start");
  try {
    const token = await native().getBiddingTokenAsync();
    vungleLog.info("getVungleBiddingToken_complete", `len=${token.length}`);
    return token;
  } catch (e) {
    vungleLog.error("getVungleBiddingToken_failed", e instanceof Error ? e.message : String(e));
    throw e;
  }
}

/**
 * Subscribe to all native lifecycle / diagnostic events (single channel `onVungle`).
 */
export function addVungleEventListener(
  listener: (event: VungleNativeEvent) => void
): EventSubscription {
  const n = native();
  vungleLog.debug("addVungleEventListener", "subscribed");
  return n.addListener("onVungle", (event) => {
    listener(event as VungleNativeEvent);
  });
}

/**
 * Rewarded placement helper — load / show / destroy map to the native `RewardedAd` / `VungleRewarded` instance for this placement id.
 */
export class VungleRewardedAd {
  constructor(public readonly placementId: string) {
    vungleLog.debug("VungleRewardedAd_construct", placementId);
  }

  async load(options?: VungleRewardedLoadOptions): Promise<void> {
    const userId = options?.userId ?? null;
    const adMarkup = options?.adMarkup ?? null;
    const bidding = typeof adMarkup === "string" && adMarkup.length > 0;
    vungleLog.info(
      "VungleRewardedAd_load_start",
      `${this.placementId} userIdSet=${String(!!userId && userId.length > 0)} bidding=${String(bidding)}`
    );
    await native().loadRewardedAsync(this.placementId, userId, adMarkup);
    vungleLog.info("VungleRewardedAd_load_complete", this.placementId);
  }

  async show(): Promise<void> {
    vungleLog.info("VungleRewardedAd_show_start", this.placementId);
    await native().showRewardedAsync(this.placementId);
    vungleLog.info("VungleRewardedAd_show_complete", this.placementId);
  }

  async destroy(): Promise<void> {
    vungleLog.info("VungleRewardedAd_destroy", this.placementId);
    await native().destroyRewardedAsync(this.placementId);
  }
}
