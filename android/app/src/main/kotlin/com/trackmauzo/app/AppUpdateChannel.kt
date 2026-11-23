package com.trackmauzo.app

import android.app.Activity
import android.util.Log
import com.google.android.play.core.appupdate.AppUpdateManager
import com.google.android.play.core.appupdate.AppUpdateManagerFactory
import com.google.android.play.core.appupdate.AppUpdateOptions
import com.google.android.play.core.install.InstallStateUpdatedListener
import com.google.android.play.core.install.model.AppUpdateType
import com.google.android.play.core.install.model.InstallStatus
import com.google.android.play.core.install.model.UpdateAvailability
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.lang.ref.WeakReference

object AppUpdateChannel {
    private const val CHANNEL = "trackmauzo/app_update"
    private const val TAG = "AppUpdateChannel"
    private const val UPDATE_REQUEST_CODE = 9412

    private var channel: MethodChannel? = null
    private var appUpdateManager: AppUpdateManager? = null
    private var installStateListener: InstallStateUpdatedListener? = null
    private var activityRef: WeakReference<Activity>? = null

    fun register(messenger: BinaryMessenger, activity: Activity) {
        onDestroy()
        activityRef = WeakReference(activity)
        val manager = AppUpdateManagerFactory.create(activity.applicationContext)
        appUpdateManager = manager

        val methodChannel = MethodChannel(messenger, CHANNEL)
        channel = methodChannel

        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "checkAndStartAutoUpdate" -> {
                    val forceImmediate = call.argument<Boolean>("forceImmediate") ?: false
                    checkAndStartAutoUpdate(forceImmediate, result)
                }

                "completeUpdate" -> completeUpdate(result)

                else -> result.notImplemented()
            }
        }
    }

    private fun checkAndStartAutoUpdate(
        forceImmediate: Boolean,
        result: MethodChannel.Result
    ) {
        val manager = appUpdateManager
        val activity = activityRef?.get()
        if (manager == null || activity == null || activity.isFinishing || activity.isDestroyed) {
            result.success("unavailable")
            return
        }

        try {
            manager.appUpdateInfo
                .addOnSuccessListener { info ->
                    val currentActivity = activityRef?.get()
                    if (currentActivity == null || currentActivity.isFinishing || currentActivity.isDestroyed) {
                        result.success("unavailable")
                        return@addOnSuccessListener
                    }

                    if (info.installStatus() == InstallStatus.DOWNLOADED) {
                        manager.completeUpdate()
                        result.success("installing")
                        return@addOnSuccessListener
                    }

                    if (info.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS &&
                        info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)
                    ) {
                        val started = manager.startUpdateFlowForResult(
                            info,
                            currentActivity,
                            AppUpdateOptions.defaultOptions(AppUpdateType.IMMEDIATE),
                            UPDATE_REQUEST_CODE
                        )
                        result.success(if (started) "immediate_started" else "unavailable")
                        return@addOnSuccessListener
                    }

                    if (info.updateAvailability() != UpdateAvailability.UPDATE_AVAILABLE) {
                        result.success("up_to_date")
                        return@addOnSuccessListener
                    }

                    val preferImmediate = forceImmediate || info.updatePriority() >= 4
                    if (preferImmediate && info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
                        val started = manager.startUpdateFlowForResult(
                            info,
                            currentActivity,
                            AppUpdateOptions.defaultOptions(AppUpdateType.IMMEDIATE),
                            UPDATE_REQUEST_CODE
                        )
                        result.success(if (started) "immediate_started" else "unavailable")
                        return@addOnSuccessListener
                    }

                    if (info.isUpdateTypeAllowed(AppUpdateType.FLEXIBLE)) {
                        registerFlexibleListener(manager)
                        val started = manager.startUpdateFlowForResult(
                            info,
                            currentActivity,
                            AppUpdateOptions.defaultOptions(AppUpdateType.FLEXIBLE),
                            UPDATE_REQUEST_CODE
                        )
                        result.success(if (started) "flexible_started" else "unavailable")
                        return@addOnSuccessListener
                    }

                    if (info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE)) {
                        val started = manager.startUpdateFlowForResult(
                            info,
                            currentActivity,
                            AppUpdateOptions.defaultOptions(AppUpdateType.IMMEDIATE),
                            UPDATE_REQUEST_CODE
                        )
                        result.success(if (started) "immediate_started" else "unavailable")
                        return@addOnSuccessListener
                    }

                    result.success("up_to_date")
                }
                .addOnFailureListener { error ->
                    Log.d(TAG, "Play in-app update check unavailable: ${error.message}")
                    result.success("unavailable")
                }
        } catch (error: Exception) {
            Log.d(TAG, "Play in-app update check failed silently: ${error.message}")
            result.success("unavailable")
        }
    }

    private fun registerFlexibleListener(manager: AppUpdateManager) {
        unregisterListener(manager)
        lateinit var listener: InstallStateUpdatedListener
        listener = InstallStateUpdatedListener { state ->
            if (state.installStatus() == InstallStatus.DOWNLOADED) {
                unregisterListener(manager)
                val activity = activityRef?.get()
                if (activity != null && !activity.isFinishing && !activity.isDestroyed) {
                    activity.runOnUiThread {
                        channel?.invokeMethod("onUpdateDownloaded", null)
                    }
                } else {
                    manager.completeUpdate()
                }
            }
        }
        installStateListener = listener
        manager.registerListener(listener)
    }

    private fun completeUpdate(result: MethodChannel.Result) {
        val manager = appUpdateManager
        if (manager == null) {
            result.success(false)
            return
        }
        try {
            manager.completeUpdate()
                .addOnSuccessListener { result.success(true) }
                .addOnFailureListener { result.success(false) }
        } catch (_: Exception) {
            result.success(false)
        }
    }

    fun onResume(activity: Activity) {
        activityRef = WeakReference(activity)
        val manager = appUpdateManager ?: return
        try {
            manager.appUpdateInfo.addOnSuccessListener { info ->
                if (info.installStatus() == InstallStatus.DOWNLOADED) {
                    manager.completeUpdate()
                } else if (
                    info.updateAvailability() == UpdateAvailability.DEVELOPER_TRIGGERED_UPDATE_IN_PROGRESS &&
                    info.isUpdateTypeAllowed(AppUpdateType.IMMEDIATE) &&
                    !activity.isFinishing &&
                    !activity.isDestroyed
                ) {
                    manager.startUpdateFlowForResult(
                        info,
                        activity,
                        AppUpdateOptions.defaultOptions(AppUpdateType.IMMEDIATE),
                        UPDATE_REQUEST_CODE
                    )
                }
            }
        } catch (error: Exception) {
            Log.d(TAG, "onResume update check skipped: ${error.message}")
        }
    }

    fun onDestroy() {
        val manager = appUpdateManager
        if (manager != null) {
            unregisterListener(manager)
        }
        channel?.setMethodCallHandler(null)
        channel = null
        appUpdateManager = null
        activityRef = null
    }

    private fun unregisterListener(manager: AppUpdateManager) {
        val existing = installStateListener ?: return
        try {
            manager.unregisterListener(existing)
        } catch (_: Exception) {
        }
        installStateListener = null
    }
}
