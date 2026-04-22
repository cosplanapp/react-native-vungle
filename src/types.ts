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
};
