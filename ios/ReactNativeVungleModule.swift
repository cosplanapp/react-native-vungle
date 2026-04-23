import ExpoModulesCore
import Foundation
import UIKit
import VungleAdsSDK

private let vungleEventName = "onVungle"
private let logTag = "ReactNativeVungle"

private func topViewController() -> UIViewController? {
  let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
  for scene in scenes where scene.activationState == .foregroundActive {
    if let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
      var top = root
      while let presented = top.presentedViewController {
        top = presented
      }
      return top
    }
  }
  if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
     let root = scene.windows.first?.rootViewController {
    var top = root
    while let presented = top.presentedViewController {
      top = presented
    }
    return top
  }
  return nil
}

private final class RewardedBridge: NSObject, VungleRewardedDelegate {
  weak var owner: ReactNativeVungleModule?
  let placementId: String

  init(owner: ReactNativeVungleModule, placementId: String) {
    self.owner = owner
    self.placementId = placementId
  }

  func rewardedAdDidLoad(_ rewarded: VungleRewarded) {
    owner?.logNative("rewardedAdDidLoad", detail: placementId)
    owner?.emit(kind: "rewardedAdLoaded", placementId: placementId)
    owner?.finishLoadContinuation(placementId: placementId, error: nil)
  }

  func rewardedAdDidFailToLoad(_ rewarded: VungleRewarded, withError: NSError) {
    owner?.logNative("rewardedAdDidFailToLoad", detail: "\(placementId) \(withError.code) \(withError.localizedDescription)")
    owner?.emit(
      kind: "rewardedAdFailedToLoad",
      placementId: placementId,
      extra: ["code": String(withError.code), "message": withError.localizedDescription]
    )
    owner?.finishLoadContinuation(
      placementId: placementId,
      error: Exception(
        name: "VungleLoadFailed",
        description: withError.localizedDescription,
        code: "ERR_VUNGLE_LOAD_FAILED"
      )
    )
  }

  func rewardedAdWillPresent(_ rewarded: VungleRewarded) {
    owner?.logNative("rewardedAdWillPresent", detail: placementId)
    owner?.emit(kind: "rewardedAdWillPresent", placementId: placementId)
  }

  func rewardedAdDidPresent(_ rewarded: VungleRewarded) {
    owner?.logNative("rewardedAdDidPresent", detail: placementId)
    owner?.emit(kind: "rewardedAdStarted", placementId: placementId)
  }

  func rewardedAdDidFailToPresent(_ rewarded: VungleRewarded, withError: NSError) {
    owner?.logNative("rewardedAdDidFailToPresent", detail: "\(placementId) \(withError.code)")
    owner?.emit(
      kind: "rewardedAdFailedToPlay",
      placementId: placementId,
      extra: ["code": String(withError.code), "message": withError.localizedDescription]
    )
    owner?.finishShowContinuation(
      placementId: placementId,
      error: Exception(
        name: "VunglePlayFailed",
        description: withError.localizedDescription,
        code: "ERR_VUNGLE_PLAY_FAILED"
      )
    )
  }

  func rewardedAdDidTrackImpression(_ rewarded: VungleRewarded) {
    owner?.logNative("rewardedAdDidTrackImpression", detail: placementId)
    owner?.emit(kind: "rewardedAdImpression", placementId: placementId)
  }

  func rewardedAdDidClick(_ rewarded: VungleRewarded) {
    owner?.logNative("rewardedAdDidClick", detail: placementId)
    owner?.emit(kind: "rewardedAdClicked", placementId: placementId)
  }

  func rewardedAdWillLeaveApplication(_ rewarded: VungleRewarded) {
    owner?.logNative("rewardedAdWillLeaveApplication", detail: placementId)
    owner?.emit(kind: "rewardedAdLeftApplication", placementId: placementId)
  }

  func rewardedAdDidRewardUser(_ rewarded: VungleRewarded) {
    owner?.logNative("rewardedAdDidRewardUser", detail: placementId)
    owner?.emit(kind: "rewardedUserRewarded", placementId: placementId)
  }

  func rewardedAdWillClose(_ rewarded: VungleRewarded) {
    owner?.logNative("rewardedAdWillClose", detail: placementId)
    owner?.emit(kind: "rewardedAdWillClose", placementId: placementId)
  }

  func rewardedAdDidClose(_ rewarded: VungleRewarded) {
    owner?.logNative("rewardedAdDidClose", detail: placementId)
    owner?.emit(kind: "rewardedAdEnded", placementId: placementId)
    owner?.finishShowContinuation(placementId: placementId, error: nil)
  }
}

public final class ReactNativeVungleModule: Module {
  private let stateLock = NSLock()
  private var loggingEnabled = true
  private var initSucceeded = false
  private var rewardedAds: [String: VungleRewarded] = [:]
  private var bridges: [String: RewardedBridge] = [:]
  private var loadContinuations: [String: CheckedContinuation<Void, Error>] = [:]
  private var showContinuations: [String: CheckedContinuation<Void, Error>] = [:]

  fileprivate func logNative(_ step: String, detail: String? = nil) {
    stateLock.lock()
    let enabled = loggingEnabled
    stateLock.unlock()
    if !enabled {
      return
    }
    if let detail = detail {
      NSLog("[%@] %@ — %@", logTag, step, detail)
    } else {
      NSLog("[%@] %@", logTag, step)
    }
  }

  fileprivate func emit(kind: String, placementId: String? = nil, extra: [String: Any] = [:]) {
    var body: [String: Any?] = ["kind": kind]
    if let placementId = placementId {
      body["placementId"] = placementId
    }
    for (k, v) in extra {
      body[k] = v
    }
    sendEvent(vungleEventName, body)
  }

  fileprivate func finishLoadContinuation(placementId: String, error: Error?) {
    stateLock.lock()
    let cont = loadContinuations.removeValue(forKey: placementId)
    stateLock.unlock()
    guard let cont = cont else {
      return
    }
    if let error = error {
      cont.resume(throwing: error)
    } else {
      cont.resume()
    }
  }

  fileprivate func finishShowContinuation(placementId: String, error: Error?) {
    stateLock.lock()
    let cont = showContinuations.removeValue(forKey: placementId)
    stateLock.unlock()
    guard let cont = cont else {
      return
    }
    if let error = error {
      cont.resume(throwing: error)
    } else {
      cont.resume()
    }
  }

  public func definition() -> ModuleDefinition {
    Name("ReactNativeVungle")

    Events(vungleEventName)

    Function("getSdkVersionSync") { () -> String in
      VungleAds.sdkVersion
    }

    Function("setLoggingEnabled") { (enabled: Bool) in
      self.stateLock.lock()
      self.loggingEnabled = enabled
      self.stateLock.unlock()
      self.logNative("setLoggingEnabled", detail: String(enabled))
    }

    AsyncFunction("initSdkAsync") { (appId: String, loggingEnabledArg: Bool) async throws -> Bool in
      self.stateLock.lock()
      self.loggingEnabled = loggingEnabledArg
      self.stateLock.unlock()
      self.logNative("initSdkAsync_start", detail: "appIdLength=\(appId.count)")

      if VungleAds.isInitialized() {
        self.stateLock.lock()
        self.initSucceeded = true
        self.stateLock.unlock()
        self.logNative("initSdkAsync_skip", detail: "already_initialized")
        self.emit(kind: "sdkInitSkipped", extra: ["reason": "already_initialized"])
        return true
      }

      return try await withCheckedThrowingContinuation { continuation in
        VungleAds.initWithAppId(appId) { error in
          if let error = error {
            let nsError = error as NSError
            self.logNative("initSdkAsync_error", detail: "\(nsError.code) \(error.localizedDescription)")
            self.emit(
              kind: "sdkInitialized",
              extra: [
                "success": false,
                "code": String(nsError.code),
                "message": error.localizedDescription
              ]
            )
            continuation.resume(
              throwing: Exception(
                name: "VungleInitFailed",
                description: error.localizedDescription,
                code: "ERR_VUNGLE_INIT"
              )
            )
          } else {
            self.stateLock.lock()
            self.initSucceeded = true
            self.stateLock.unlock()
            self.logNative("initSdkAsync_success")
            self.emit(kind: "sdkInitialized", extra: ["success": true])
            continuation.resume(returning: true)
          }
        }
      }
    }

    AsyncFunction("loadRewardedAsync") { (placementId: String, userId: String?) async throws -> Bool in
      self.stateLock.lock()
      let initialized = self.initSucceeded
      self.stateLock.unlock()
      if !initialized {
        throw Exception(
          name: "VungleNotInitialized",
          description: "Call initSdkAsync first",
          code: "ERR_VUNGLE_NOT_INITIALIZED"
        )
      }

      self.stateLock.lock()
      if let old = self.rewardedAds.removeValue(forKey: placementId) {
        old.delegate = nil
      }
      self.bridges.removeValue(forKey: placementId)
      self.stateLock.unlock()

      self.logNative("loadRewarded_start", detail: placementId)
      self.emit(kind: "rewardedLoadStarted", placementId: placementId)

      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        self.stateLock.lock()
        if let oldCont = self.loadContinuations.removeValue(forKey: placementId) {
          self.stateLock.unlock()
          oldCont.resume(
            throwing: Exception(
              name: "VungleLoadReplaced",
              description: "Superseded by new load",
              code: "ERR_VUNGLE_LOAD_REPLACED"
            )
          )
          self.stateLock.lock()
        }
        self.loadContinuations[placementId] = continuation
        self.stateLock.unlock()

        let rewarded = VungleRewarded(placementId: placementId)
        let bridge = RewardedBridge(owner: self, placementId: placementId)
        rewarded.delegate = bridge
        if let userId = userId, !userId.isEmpty {
          rewarded.setUserIdWithUserId(userId)
          self.logNative("loadRewarded_userId", detail: "setUserIdWithUserId len=\(userId.count)")
        }

        self.stateLock.lock()
        self.rewardedAds[placementId] = rewarded
        self.bridges[placementId] = bridge
        self.stateLock.unlock()

        rewarded.load()
      }

      return true
    }

    AsyncFunction("showRewardedAsync") { (placementId: String) async throws -> Bool in
      self.stateLock.lock()
      let initialized = self.initSucceeded
      let rewarded = self.rewardedAds[placementId]
      self.stateLock.unlock()

      if !initialized {
        throw Exception(
          name: "VungleNotInitialized",
          description: "Call initSdkAsync first",
          code: "ERR_VUNGLE_NOT_INITIALIZED"
        )
      }
      guard let rewarded = rewarded else {
        throw Exception(
          name: "VungleAdMissing",
          description: "No ad for placement \(placementId)",
          code: "ERR_VUNGLE_AD_MISSING"
        )
      }

      self.logNative("showRewarded_check", detail: placementId)
      guard rewarded.canPlayAd() else {
        self.emit(
          kind: "rewardedAdShowRejected",
          placementId: placementId,
          extra: ["reason": "canPlayAd_false"]
        )
        throw Exception(
          name: "VungleCannotPlay",
          description: "canPlayAd() is false for \(placementId)",
          code: "ERR_VUNGLE_CANNOT_PLAY"
        )
      }

      self.emit(kind: "rewardedAdWillShow", placementId: placementId)

      guard let presenter = topViewController() else {
        throw Exception(
          name: "VungleNoViewController",
          description: "Could not find a UIViewController to present the ad",
          code: "ERR_VUNGLE_NO_VIEW_CONTROLLER"
        )
      }

      try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        self.stateLock.lock()
        if let oldCont = self.showContinuations.removeValue(forKey: placementId) {
          self.stateLock.unlock()
          oldCont.resume(
            throwing: Exception(
              name: "VungleShowReplaced",
              description: "Superseded by new show",
              code: "ERR_VUNGLE_SHOW_REPLACED"
            )
          )
          self.stateLock.lock()
        }
        self.showContinuations[placementId] = continuation
        self.stateLock.unlock()

        rewarded.present(with: presenter)
      }

      return true
    }

    AsyncFunction("destroyRewardedAsync") { (placementId: String) async throws -> Bool in
      self.stateLock.lock()
      if let rewarded = self.rewardedAds.removeValue(forKey: placementId) {
        rewarded.delegate = nil
        self.bridges.removeValue(forKey: placementId)
        self.stateLock.unlock()
        self.logNative("destroyRewarded", detail: placementId)
        self.emit(kind: "rewardedAdDestroyed", placementId: placementId)
      } else {
        self.stateLock.unlock()
      }

      self.finishLoadContinuation(
        placementId: placementId,
        error: Exception(
          name: "VungleDestroyed",
          description: "Ad destroyed",
          code: "ERR_VUNGLE_DESTROYED"
        )
      )
      self.finishShowContinuation(
        placementId: placementId,
        error: Exception(
          name: "VungleDestroyed",
          description: "Ad destroyed",
          code: "ERR_VUNGLE_DESTROYED"
        )
      )
      return true
    }
  }
}
