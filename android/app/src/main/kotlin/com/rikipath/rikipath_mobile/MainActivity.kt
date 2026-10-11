package com.rikipath.rikipath_mobile

import android.app.PictureInPictureParams
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Rational
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    companion object {
        private const val meetingPipChannel =
            "com.rikipath.rikipath_mobile/meeting_pip"
    }

    private var pipChannel: MethodChannel? = null
    private var pipEligible = false
    private var pipSessionActive = false
    private var pipDismissalReported = false
    private val mainHandler = Handler(Looper.getMainLooper())
    private val pipDismissalCheck = Runnable { reportPipDismissalIfNeeded() }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pipChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            meetingPipChannel,
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                when (call.method) {
                    "isSupported" -> result.success(isPipSupported())
                    "isInPip" -> result.success(isCurrentlyInPip())
                    "setAutoEnterEnabled" -> {
                        pipEligible = call.argument<Boolean>("enabled") == true
                        updatePipParams()
                        result.success(null)
                    }
                    "enter" -> result.success(enterMeetingPip())
                    else -> result.notImplemented()
                }
            }
        }
    }

    private fun isPipSupported(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            packageManager.hasSystemFeature(PackageManager.FEATURE_PICTURE_IN_PICTURE)
    }

    private fun isCurrentlyInPip(): Boolean {
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            isInPictureInPictureMode
    }

    private fun buildPipParams(): PictureInPictureParams {
        val builder = PictureInPictureParams.Builder()
            .setAspectRatio(Rational(16, 9))
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            builder.setAutoEnterEnabled(pipEligible)
            builder.setSeamlessResizeEnabled(true)
        }
        return builder.build()
    }

    private fun updatePipParams() {
        if (!isPipSupported()) return
        setPictureInPictureParams(buildPipParams())
    }

    private fun enterMeetingPip(): Boolean {
        if (!isPipSupported() || !pipEligible || isCurrentlyInPip()) return false
        return enterPictureInPictureMode(buildPipParams())
    }

    override fun onUserLeaveHint() {
        if (
            pipEligible &&
            Build.VERSION.SDK_INT in Build.VERSION_CODES.O until Build.VERSION_CODES.S
        ) {
            enterMeetingPip()
        }
        super.onUserLeaveHint()
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration,
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        if (isInPictureInPictureMode) {
            pipSessionActive = true
            pipDismissalReported = false
            mainHandler.removeCallbacks(pipDismissalCheck)
        } else {
            schedulePipDismissalCheck()
        }
        pipChannel?.invokeMethod(
            "onPipModeChanged",
            mapOf("isInPip" to isInPictureInPictureMode),
        )
    }

    override fun onResume() {
        super.onResume()
        if (!isCurrentlyInPip()) {
            mainHandler.removeCallbacks(pipDismissalCheck)
            pipSessionActive = false
        }
    }

    override fun onStop() {
        schedulePipDismissalCheck()
        super.onStop()
    }

    private fun schedulePipDismissalCheck() {
        if (!pipSessionActive || isChangingConfigurations) return
        mainHandler.removeCallbacks(pipDismissalCheck)
        // Closing PiP can deliver onStop before the final PiP-mode callback.
        // A short delay lets both callbacks settle, while onResume cancels the
        // check when the user expands the same meeting back to full screen.
        mainHandler.postDelayed(pipDismissalCheck, 300L)
    }

    private fun reportPipDismissalIfNeeded() {
        if (
            !pipSessionActive ||
            pipDismissalReported ||
            isCurrentlyInPip() ||
            hasWindowFocus() ||
            isChangingConfigurations
        ) {
            return
        }
        pipDismissalReported = true
        pipSessionActive = false
        pipChannel?.invokeMethod("onPipDismissed", null)
    }

    override fun cleanUpFlutterEngine(flutterEngine: FlutterEngine) {
        mainHandler.removeCallbacks(pipDismissalCheck)
        pipChannel?.setMethodCallHandler(null)
        pipChannel = null
        super.cleanUpFlutterEngine(flutterEngine)
    }
}
