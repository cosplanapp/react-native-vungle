# react-native-vungle

Expo module (Kotlin + Swift) wrapping **Liftoff Monetize / VungleAds SDK 7.7.x** for React Native. This package currently exposes **rewarded ads only**, with a single native event channel and verbose logging you can turn off in production.

## Documentation (official)

- **Native Android SDK (init, Gradle, formats, etc.)** — open in a normal browser: [Integrate Vungle SDK for Android or Amazon](https://support.vungle.com/hc/en-us/articles/360002922871-Integrate-Vungle-SDK-for-Android-or-Amazon) (Zendesk may block automated fetches; the same URL is the reference for SDK setup).
- **Placements with In-App Bidding** — Liftoff dashboard and rewarded placement options are described in Google’s mediation guide (toggle *In-App Bidding* on the placement): [AdMob — Integrate Liftoff Monetize with mediation (Android)](https://developers.google.com/admob/android/mediation/liftoff-monetize).
- Product / SDK hub: [Liftoff — Vungle SDK](https://liftoff.ai/monetize/vungle-sdk/)
- Android artifact: `com.vungle:vungle-ads` (declared in this library’s `android/build.gradle`)
- iOS pod: `VungleAds` (declared in `ios/ReactNativeVungle.podspec`)

## Requirements

- Expo SDK **54+** (EAS / prebuild compatible)
- React Native **0.81+**
- iOS **15.1+**

## Install

In your app (monorepo example):

```json
{
  "dependencies": {
    "react-native-vungle": "file:../react-native-vungle"
  }
}
```

Then install pods / Gradle via your usual `npx expo prebuild` or EAS build.

### Optional: Expo config plugin (SKAdNetwork)

If you need extra SKAdNetwork IDs (see [Vungle SKAdNetwork for iOS](https://support.vungle.com/hc/en-us/articles/360047771052-SKAdNetwork-for-iOS)), merge them without editing the plist by hand:

```json
{
  "expo": {
    "plugins": [
      [
        "react-native-vungle",
        {
          "skAdNetworkIdentifiers": ["your.skadnetwork.id"]
        }
      ]
    ]
  }
}
```

## Usage

```ts
import {
  initVungle,
  getVungleBiddingToken,
  VungleRewardedAd,
  addVungleEventListener,
  setJsLoggingEnabled,
} from "react-native-vungle";

const unsub = addVungleEventListener((e) => {
  console.log("Vungle event:", e.kind, e.placementId, e);
});

await initVungle({
  appId: "YOUR_LIFTOFF_APP_ID",
  loggingEnabled: __DEV__, // set false in production
});

const rewarded = new VungleRewardedAd("YOUR_REWARDED_PLACEMENT_ID");
await rewarded.load({ userId: "optional-user-id" }); // userId is applied on Android native SDK
await rewarded.show();
await rewarded.destroy();

// Android — in-app / header bidding placement (after init):
// 1) Token for your auction: `const token = await getVungleBiddingToken();`
// 2) Run the auction server- or exchange-side; use the returned bid payload string as `adMarkup`.
// 3) `await rewarded.load({ adMarkup: "<bid-response-from-auction>" });`
// iOS: `getVungleBiddingToken` and non-empty `adMarkup` reject with `ERR_VUNGLE_BIDDING_ANDROID_ONLY`.

unsub.remove();

// Late: disable all JS-side logs (native logs follow setLoggingEnabled from init)
setJsLoggingEnabled(false);
```

### Logging

- **JavaScript**: `vungleLog` and logs inside `initVungle` / `VungleRewardedAd` respect `loggingEnabled` from `initVungle` (default `__DEV__`). Use `setJsLoggingEnabled(false)` to silence JS logs at runtime.
- **Native**: `initVungle` forwards `loggingEnabled` to the native module (`setLoggingEnabled`). When `false`, Android `Log.i` / `NSLog` in this bridge are suppressed.

### Errors

Native failures surface as promise rejections with Expo **coded** errors where applicable, for example:

- `ERR_VUNGLE_INIT` — SDK init failed
- `ERR_VUNGLE_NOT_INITIALIZED` — load/show called before successful init
- `ERR_VUNGLE_LOAD_FAILED` — ad failed to load
- `ERR_VUNGLE_PLAY_FAILED` — ad failed to present
- `ERR_VUNGLE_CANNOT_PLAY` — `canPlayAd()` false at show time
- `ERR_VUNGLE_NO_VIEW_CONTROLLER` (iOS) — no `UIViewController` to present from
- `ERR_VUNGLE_BID_TOKEN` (Android) — `getVungleBiddingToken` / native bid token collection failed
- `ERR_VUNGLE_BIDDING_ANDROID_ONLY` (iOS) — `getVungleBiddingToken` or `load` with `adMarkup` is not implemented on iOS in this module

## Notes

- **Mediation vs direct SDK**: If you already use **Google Mobile Ads + Liftoff mediation**, adding this direct SDK duplicates the Vungle stack and increases binary size. Use one approach per build unless you know you need both.
- **iOS `userId`**: The Android bridge forwards `userId` to `RewardedAd.setUserId`. On iOS, `userId` is accepted in JS for API parity but not applied in native v0.1 (confirm the exact `VungleRewarded` API for your pinned pod before enabling).

## License

MIT
