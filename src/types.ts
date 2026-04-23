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
   * Android: `RewardedAd.setUserId` before load.
   * iOS (VungleAds 7.x): `VungleRewarded.setUserIdWithUserId` before load (S2S / rewarded user id).
   */
  userId?: string | null;
};
