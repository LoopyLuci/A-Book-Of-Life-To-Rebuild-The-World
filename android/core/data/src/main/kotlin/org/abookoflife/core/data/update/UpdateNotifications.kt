package org.abookoflife.core.data.update

import android.Manifest
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import org.abookoflife.core.data.R

internal object UpdateNotifications {

    fun available(context: Context, releaseTag: String): Boolean {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return false
        val notification = NotificationCompat.Builder(context, channelId(context))
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(context.getString(R.string.update_available_notification_title))
            .setContentText(
                context.getString(R.string.update_available_notification_text, releaseTag),
            )
            .setContentIntent(pendingActivity(context, intent, AVAILABLE_NOTIFICATION_ID))
            .setAutoCancel(true)
            .build()
        return post(context, AVAILABLE_NOTIFICATION_ID, notification)
    }

    fun downloaded(
        context: Context,
        releaseTag: String,
        installIntent: Intent?,
    ): Boolean {
        val intent = installIntent
            ?: context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return false
        val installRequested = installIntent != null
        val notification = NotificationCompat.Builder(context, channelId(context))
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setContentTitle(context.getString(R.string.update_downloaded_notification_title))
            .setContentText(
                context.getString(
                    if (installRequested) {
                        R.string.update_install_notification_text
                    } else {
                        R.string.update_downloaded_notification_text
                    },
                    releaseTag,
                ),
            )
            .setContentIntent(pendingActivity(context, intent, DOWNLOAD_NOTIFICATION_ID))
            .setAutoCancel(true)
            .apply {
                if (installRequested) {
                    addAction(
                        0,
                        context.getString(R.string.update_notification_action),
                        pendingActivity(context, intent, INSTALL_NOTIFICATION_ID),
                    )
                }
            }
            .build()
        return post(context, DOWNLOAD_NOTIFICATION_ID, notification)
    }

    fun checkFailed(context: Context): Boolean {
        val intent = context.packageManager.getLaunchIntentForPackage(context.packageName)
            ?: return false
        val notification = NotificationCompat.Builder(context, channelId(context))
            .setSmallIcon(android.R.drawable.stat_notify_error)
            .setContentTitle(context.getString(R.string.update_check_failed_notification_title))
            .setContentText(context.getString(R.string.update_check_failed_notification_text))
            .setContentIntent(pendingActivity(context, intent, FAILED_NOTIFICATION_ID))
            .setAutoCancel(true)
            .build()
        return post(context, FAILED_NOTIFICATION_ID, notification)
    }

    private fun channelId(context: Context): String {
        val id = context.getString(R.string.update_channel_id)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                id,
                context.getString(R.string.update_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT,
            )
            context.getSystemService(NotificationManager::class.java).createNotificationChannel(channel)
        }
        return id
    }

    private fun pendingActivity(context: Context, intent: Intent, requestCode: Int): PendingIntent {
        val flags = PendingIntent.FLAG_UPDATE_CURRENT or
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                PendingIntent.FLAG_IMMUTABLE
            } else {
                0
            }
        return PendingIntent.getActivity(context, requestCode, intent, flags)
    }

    private fun post(
        context: Context,
        notificationId: Int,
        notification: android.app.Notification,
    ): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU &&
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.POST_NOTIFICATIONS,
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            Log.w(TAG, "Notification permission is not granted; update alert was not shown")
            return false
        }
        if (!NotificationManagerCompat.from(context).areNotificationsEnabled()) {
            Log.w(TAG, "App notifications are disabled; update alert was not shown")
            return false
        }
        return try {
            NotificationManagerCompat.from(context).notify(notificationId, notification)
            true
        } catch (error: SecurityException) {
            Log.w(TAG, "Could not show update notification", error)
            false
        }
    }

    private const val TAG = "UpdateNotifications"
    private const val AVAILABLE_NOTIFICATION_ID = 4200
    private const val DOWNLOAD_NOTIFICATION_ID = 4201
    private const val INSTALL_NOTIFICATION_ID = 4202
    private const val FAILED_NOTIFICATION_ID = 4203
}
