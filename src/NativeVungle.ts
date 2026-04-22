import { requireNativeModule } from "expo-modules-core";

export type NativeVungleModule = {
  addListener(eventName: string, listener: (event: Record<string, unknown>) => void): { remove(): void };
  getSdkVersionSync(): string;
  setLoggingEnabled(enabled: boolean): void;
  initSdkAsync(appId: string, loggingEnabled: boolean): Promise<boolean>;
  getBiddingTokenAsync(): Promise<string>;
  loadRewardedAsync(placementId: string, userId: string | null, adMarkup: string | null): Promise<boolean>;
  showRewardedAsync(placementId: string): Promise<boolean>;
  destroyRewardedAsync(placementId: string): Promise<boolean>;
};

export function getNativeVungleModule(): NativeVungleModule {
  return requireNativeModule<NativeVungleModule>("ReactNativeVungle");
}
