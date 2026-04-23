package expo.modules.vungle

import android.util.Log
import com.vungle.ads.AdConfig
import com.vungle.ads.BaseAd
import com.vungle.ads.InitializationListener
import com.vungle.ads.RewardedAd
import com.vungle.ads.RewardedAdListener
import com.vungle.ads.VungleAds
import com.vungle.ads.VungleError
import expo.modules.kotlin.exception.CodedException
import expo.modules.kotlin.exception.Exceptions
import expo.modules.kotlin.functions.Coroutine
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import java.util.concurrent.ConcurrentHashMap
import kotlin.coroutines.Continuation
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

private const val TAG = "ReactNativeVungle"
private const val EVENT = "onVungle"

class ReactNativeVungleModule : Module() {
  @Volatile
  private var loggingEnabled: Boolean = true

  @Volatile
  private var initSucceeded: Boolean = false

  private val rewardedAds = ConcurrentHashMap<String, RewardedAd>()
  private val loadContinuations = ConcurrentHashMap<String, Continuation<Unit>>()
  private val showContinuations = ConcurrentHashMap<String, Continuation<Unit>>()

  private fun logNative(step: String, detail: String? = null) {
    if (!loggingEnabled) {
      return
    }
    val msg = if (detail == null) step else "$step — $detail"
    Log.i(TAG, msg)
  }

  private fun emit(kind: String, placementId: String? = null, extra: Map<String, Any?> = emptyMap()) {
    val payload = HashMap<String, Any?>(extra.size + 2)
    payload["kind"] = kind
    if (placementId != null) {
      payload["placementId"] = placementId
    }
    payload.putAll(extra)
    sendEvent(EVENT, payload)
  }

  private fun rewardedListener(placementId: String): RewardedAdListener {
    return object : RewardedAdListener {
      override fun onAdLoaded(baseAd: BaseAd) {
        logNative("rewarded_onAdLoaded", placementId)
        emit("rewardedAdLoaded", placementId)
        finishLoadContinuation(placementId, null)
      }

      override fun onAdStart(baseAd: BaseAd) {
        logNative("rewarded_onAdStart", placementId)
        emit("rewardedAdStarted", placementId)
      }

      override fun onAdImpression(baseAd: BaseAd) {
        logNative("rewarded_onAdImpression", placementId)
        emit("rewardedAdImpression", placementId)
      }

      override fun onAdEnd(baseAd: BaseAd) {
        logNative("rewarded_onAdEnd", placementId)
        emit("rewardedAdEnded", placementId)
        finishShowContinuation(placementId, null)
      }

      override fun onAdClicked(baseAd: BaseAd) {
        logNative("rewarded_onAdClicked", placementId)
        emit("rewardedAdClicked", placementId)
      }

      override fun onAdRewarded(baseAd: BaseAd) {
        logNative("rewarded_onAdRewarded", placementId)
        emit("rewardedUserRewarded", placementId)
      }

      override fun onAdLeftApplication(baseAd: BaseAd) {
        logNative("rewarded_onAdLeftApplication", placementId)
        emit("rewardedAdLeftApplication", placementId)
      }

      override fun onAdFailedToLoad(baseAd: BaseAd, adError: VungleError) {
        val code = adError.code.toString()
        val msg = adError.localizedMessage ?: "load_failed"
        logNative("rewarded_onAdFailedToLoad", "$placementId $code $msg")
        emit(
          "rewardedAdFailedToLoad",
          placementId,
          mapOf("code" to code, "message" to msg)
        )
        finishLoadContinuation(
          placementId,
          CodedException("ERR_VUNGLE_LOAD_FAILED", "$code: $msg", null)
        )
      }

      override fun onAdFailedToPlay(baseAd: BaseAd, adError: VungleError) {
        val code = adError.code.toString()
        val msg = adError.localizedMessage ?: "play_failed"
        logNative("rewarded_onAdFailedToPlay", "$placementId $code $msg")
        emit(
          "rewardedAdFailedToPlay",
          placementId,
          mapOf("code" to code, "message" to msg)
        )
        finishShowContinuation(
          placementId,
          CodedException("ERR_VUNGLE_PLAY_FAILED", "$code: $msg", null)
        )
      }
    }
  }

  private fun finishLoadContinuation(placementId: String, error: Throwable?) {
    val cont = loadContinuations.remove(placementId) ?: return
    if (error == null) {
      try {
        cont.resume(Unit)
      } catch (_: Throwable) {
      }
    } else {
      try {
        cont.resumeWithException(error)
      } catch (_: Throwable) {
      }
    }
  }

  private fun finishShowContinuation(placementId: String, error: Throwable?) {
    val cont = showContinuations.remove(placementId) ?: return
    try {
      if (error == null) {
        cont.resume(Unit)
      } else {
        cont.resumeWithException(error)
      }
    } catch (_: Throwable) {
    }
  }

  override fun definition() = ModuleDefinition {
    Name("ReactNativeVungle")

    Events(EVENT)

    Function("getSdkVersionSync") {
      try {
        VungleAds.getSdkVersion()
      } catch (e: Throwable) {
        this@ReactNativeVungleModule.logNative("getSdkVersionSync_error", e.message)
        "unknown"
      }
    }

    Function("setLoggingEnabled") { enabled: Boolean ->
      this@ReactNativeVungleModule.loggingEnabled = enabled
      this@ReactNativeVungleModule.logNative("setLoggingEnabled", enabled.toString())
    }

    AsyncFunction("initSdkAsync") Coroutine { appId: String, loggingEnabledArg: Boolean ->
      val host = this@ReactNativeVungleModule
      val context = appContext.reactContext ?: throw Exceptions.ReactContextLost()
      host.loggingEnabled = loggingEnabledArg
      host.logNative("initSdkAsync_start", "appIdLength=${appId.length}")

      if (host.initSucceeded) {
        host.logNative("initSdkAsync_skip", "already_initialized")
        host.emit("sdkInitSkipped", extra = mapOf("reason" to "already_initialized"))
        return@Coroutine true
      }

      suspendCoroutine { cont ->
        VungleAds.init(context, appId, object : InitializationListener {
          override fun onSuccess() {
            host.initSucceeded = true
            host.logNative("initSdkAsync_success")
            host.emit("sdkInitialized", extra = mapOf("success" to true))
            cont.resume(Unit)
          }

          override fun onError(vungleError: VungleError) {
            val code = vungleError.code.toString()
            val msg = vungleError.localizedMessage ?: "init_error"
            host.logNative("initSdkAsync_error", "$code $msg")
            host.emit(
              "sdkInitialized",
              extra = mapOf(
                "success" to false,
                "code" to code,
                "message" to msg
              )
            )
            cont.resumeWithException(
              CodedException("ERR_VUNGLE_INIT", "$code: $msg", null)
            )
          }
        })
      }
      true
    }

    AsyncFunction("loadRewardedAsync") Coroutine { placementId: String, userId: String? ->
      val host = this@ReactNativeVungleModule
      val context = appContext.reactContext ?: throw Exceptions.ReactContextLost()
      if (!host.initSucceeded) {
        throw CodedException("ERR_VUNGLE_NOT_INITIALIZED", "Call initSdkAsync first", null)
      }

      host.rewardedAds.remove(placementId)?.adListener = null

      host.logNative("loadRewarded_start", placementId)
      host.emit("rewardedLoadStarted", placementId)

      suspendCoroutine { cont ->
        host.loadContinuations[placementId]?.let { old ->
          host.loadContinuations.remove(placementId)
          old.resumeWithException(CodedException("ERR_VUNGLE_LOAD_REPLACED", "Superseded by new load", null))
        }
        host.loadContinuations[placementId] = cont

        val ad = RewardedAd(context, placementId, AdConfig()).apply {
          if (!userId.isNullOrBlank()) {
            setUserId(userId)
          }
          adListener = host.rewardedListener(placementId)
          load(null)
        }
        host.rewardedAds[placementId] = ad
      }
      true
    }

    AsyncFunction("showRewardedAsync") Coroutine { placementId: String ->
      val host = this@ReactNativeVungleModule
      val context = appContext.reactContext ?: throw Exceptions.ReactContextLost()
      if (!host.initSucceeded) {
        throw CodedException("ERR_VUNGLE_NOT_INITIALIZED", "Call initSdkAsync first", null)
      }
      val ad = host.rewardedAds[placementId]
        ?: throw CodedException("ERR_VUNGLE_AD_MISSING", "No ad for placement $placementId", null)

      host.logNative("showRewarded_check", placementId)
      if (ad.canPlayAd() != true) {
        host.emit(
          "rewardedAdShowRejected",
          placementId,
          mapOf("reason" to "canPlayAd_false")
        )
        throw CodedException("ERR_VUNGLE_CANNOT_PLAY", "canPlayAd() is false for $placementId", null)
      }

      host.emit("rewardedAdWillShow", placementId)

      suspendCoroutine { cont ->
        host.showContinuations[placementId]?.let { old ->
          host.showContinuations.remove(placementId)
          old.resumeWithException(CodedException("ERR_VUNGLE_SHOW_REPLACED", "Superseded by new show", null))
        }
        host.showContinuations[placementId] = cont
        ad.play(context)
      }
      true
    }

    AsyncFunction("destroyRewardedAsync") Coroutine { placementId: String ->
      val host = this@ReactNativeVungleModule
      host.rewardedAds.remove(placementId)?.let { ad ->
        ad.adListener = null
        host.logNative("destroyRewarded", placementId)
        host.emit("rewardedAdDestroyed", placementId)
      }
      host.finishLoadContinuation(
        placementId,
        CodedException("ERR_VUNGLE_DESTROYED", "Ad destroyed", null)
      )
      host.finishShowContinuation(
        placementId,
        CodedException("ERR_VUNGLE_DESTROYED", "Ad destroyed", null)
      )
      true
    }
  }
}
