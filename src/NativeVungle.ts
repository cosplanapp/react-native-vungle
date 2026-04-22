import { requireNativeModule } from "expo-modules-core";

export type NativeVungleModule = {
  addListener(eventName: string, listener: (event: Record<string, unknown>) => void): { remove(): void };
  getSdkVersionSync(): string;
  setLoggingEnabled(enabled: boolean): void;
  initSdkAsync(appId: string, loggingEnabled: boolean): Promise<boolean>;
  loadRewardedAsync(placementId: string, userId: string | null): Promise<boolean>;
  showRewardedAsync(placementId: string): Promise<boolean>;
  destroyRewardedAsync(placementId: string): Promise<boolean>;
};

export function getNativeVungleModule(): NativeVungleModule {
  return requireNativeModule<NativeVungleModule>("ReactNativeVungle");
}
