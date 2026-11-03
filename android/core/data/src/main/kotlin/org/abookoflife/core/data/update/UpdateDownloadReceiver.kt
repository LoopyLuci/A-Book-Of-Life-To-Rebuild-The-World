package org.abookoflife.core.data.update

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import org.abookoflife.core.data.R

/**
 * Wakes up when the platform download service finishes, so the reader can be
 * taken to the installer even if the app was closed while the package was
 * still downloading.
 *
 * Android never allows an application to install another package without the
 * user confirming, so the receiver only prepares the platform installer and
 * asks for the confirmation.
 */
class UpdateDownloadReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != android.app.DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
        val downloadId = intent.getLongExtra(
            android.app.DownloadManager.EXTRA_DOWNLOAD_ID,
            0L,
        )
        if (downloadId == 0L) return

        val apk = UpdateDownloader(context).downloadedFile(downloadId) ?: return
        val installIntent = ApkInstaller.installIntent(context, apk)

        notifyReady(context, installIntent)

        // Works when the app is still in the foreground; the notification above
        // covers the case where the platform blocks a background launch.
        runCatching { context.startActivity(installIntent) }
    }

    private fun notifyReady(context: Context, installIntent: Intent) {
        val manager = NotificationManagerCompat.from(context)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                context.getString(R.string.update_channel_id),
                context.getString(R.string.update_channel_name),
                NotificationManager.IMPORTANCE_DEFAULT,
            )
            manager.createNotificationChannel(channel)
        }

        val flags = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        } else {
            PendingIntent.FLAG_UPDATE_CURRENT
        }
        val pendingIntent = PendingIntent.getActivity(context, 0, installIntent, flags)

        val notification = NotificationCompat.Builder(context, context.getString(R.string.update_channel_id))
            .setContentTitle(context.getString(R.string.update_notification_title))
            .setContentText(context.getString(R.string.update_notification_text))
            .setSmallIcon(android.R.drawable.stat_sys_download_done)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setAutoCancel(true)
            .setContentIntent(pendingIntent)
            .addAction(
                0,
                context.getString(R.string.update_notification_action),
                pendingIntent,
            )
            .build()

        runCatching { manager.notify(NOTIFICATION_ID, notification) }
    }

    private companion object {
        const val NOTIFICATION_ID = 4201
    }
}
