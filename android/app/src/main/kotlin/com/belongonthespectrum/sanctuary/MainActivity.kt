package com.belongonthespectrum.sanctuary

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ensureQuietBadgeChannel()
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BADGE_METHOD_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "setBadgeCount" -> {
                    val count = call.argument<Int>("count") ?: 0
                    val success = setLauncherBadgeCount(count.coerceAtLeast(0))
                    result.success(success)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun notificationManager(): NotificationManager {
        return getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    }

    private fun ensureQuietBadgeChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            QUIET_BADGE_CHANNEL_ID,
            "Unread count",
            NotificationManager.IMPORTANCE_MIN,
        ).apply {
            description = "Silent launcher badge sync (calm-tech, no sound)"
            setShowBadge(true)
            enableLights(false)
            enableVibration(false)
            setSound(null, null)
        }
        notificationManager().createNotificationChannel(channel)
    }

    private fun canPostBadgeNotification(): Boolean {
        val manager = notificationManager()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && !manager.areNotificationsEnabled()) {
            return false
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = manager.getNotificationChannel(QUIET_BADGE_CHANNEL_ID)
            if (channel != null && channel.importance == NotificationManager.IMPORTANCE_NONE) {
                return false
            }
        }
        return true
    }

    /**
     * Pixel launcher dots derive from active notifications. We post a minimal,
     * silent notification with [NotificationCompat.Builder.setNumber] and cancel
     * it when the unread count returns to zero.
     */
    private fun setLauncherBadgeCount(count: Int): Boolean {
        val manager = notificationManager()
        if (count == 0) {
            manager.cancel(BADGE_NOTIFICATION_ID)
            return true
        }
        ensureQuietBadgeChannel()
        if (!canPostBadgeNotification()) {
            return false
        }
        val notification = NotificationCompat.Builder(this, QUIET_BADGE_CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(getString(R.string.app_name))
            .setContentText(getString(R.string.badge_sync_notification_body))
            .setNumber(count)
            .setBadgeIconType(NotificationCompat.BADGE_ICON_SMALL)
            .setPriority(NotificationCompat.PRIORITY_MIN)
            .setCategory(NotificationCompat.CATEGORY_STATUS)
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setOngoing(true)
            .setAutoCancel(false)
            .build()
        manager.notify(BADGE_NOTIFICATION_ID, notification)
        return true
    }

    companion object {
        private const val BADGE_METHOD_CHANNEL = "com.belongonthespectrum.sanctuary/badge"
        private const val QUIET_BADGE_CHANNEL_ID = "calm_launcher_badge_sync"
        private const val BADGE_NOTIFICATION_ID = 0x424544 // "BED" — stable badge sync slot
    }
}
