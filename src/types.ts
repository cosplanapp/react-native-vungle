export type VungleEventKind =
  | "sdkInitialized"
  | "sdkInitSkipped"
  | "rewardedLoadStarted"
  | "rewardedAdLoaded"
  | "rewardedAdFailedToLoad"
  | "rewardedAdStarted"
  | "rewardedAdImpression"
  | "rewardedAdClicked"
  | "rewardedAdLeftApplication"
  | "rewardedUserRewarded"
  | "rewardedAdWillPresent"
  | "rewardedAdWillClose"
  | "rewardedAdEnded"
  | "rewardedAdFailedToPlay"
  | "rewardedAdWillShow"
  | "rewardedAdShowRejected"
  | "rewardedAdDestroyed";

export type VungleNativeEvent = {
  kind: VungleEventKind | string;
  placementId?: string;
  success?: boolean;
  reason?: string;
  code?: string;
  message?: string;
};

export type VungleInitOptions = {
  appId: string;
  /**
   * Verbose JS + native logs. Defaults to `__DEV__`.
   * Set explicitly to `false` in production builds when you ship with dev logging off.
   */
  loggingEnabled?: boolean;
};

export type VungleRewardedLoadOptions = {
  /**
   * Passed to the Android SDK (`RewardedAd.setUserId`).
   * iOS: reserved for a future native mapping when the public API is confirmed for your SDK pin.
   */
  userId?: string | null;
  /**
   * **Android only** — bid response / ad markup string from your auction (same as Google mediation `RewardedAd.load(adMarkup)`).
   * Omit or leave empty for waterfall placements. Required for header-bidding placements (avoids Liftoff error 224).
   * On iOS, a non-empty value rejects with `ERR_VUNGLE_BIDDING_ANDROID_ONLY`.
   */
  adMarkup?: string | null;
};
