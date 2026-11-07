package org.abookoflife.core.data.update

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class UpdateDownloadReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != android.app.DownloadManager.ACTION_DOWNLOAD_COMPLETE) return
        val downloadId = intent.getLongExtra(
            android.app.DownloadManager.EXTRA_DOWNLOAD_ID,
            0L,
        )
        if (downloadId == 0L) return

        val state = UpdateStateStore(context)
        if (state.downloadId != downloadId) return

        val downloader = UpdateDownloader(context)
        val apk = downloader.downloadedFile(downloadId) ?: return
        if (!ApkInstaller.isValidUpdate(context, apk)) {
            UpdateNotifications.invalidPackage(context)
            downloader.cancel(downloadId)
            state.clear()
            return
        }
        val installIntent = if (state.installWhenDownloaded) {
            if (ApkInstaller.canInstall(context)) {
                ApkInstaller.installIntent(context, apk)
            } else {
                ApkInstaller.permissionIntent(context)
            }
        } else {
            null
        }
        val notificationShown = UpdateNotifications.downloaded(
            context = context,
            releaseTag = state.releaseTag,
            installIntent = installIntent,
        )
        if (notificationShown && installIntent != null) {
            state.installPromptedTag = state.releaseTag
        }
    }
}
