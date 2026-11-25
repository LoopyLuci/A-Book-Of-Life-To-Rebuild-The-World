package org.abookoflife.core.data.update

import android.app.DownloadManager
import android.content.Context
import android.net.Uri
import android.os.Environment
import java.io.File

/** Progress of a background package download. */
sealed interface DownloadStatus {
    data object Pending : DownloadStatus
    data class Running(val downloadedBytes: Long, val totalBytes: Long) : DownloadStatus {
        val percent: Int
            get() = if (totalBytes > 0) {
                ((downloadedBytes * 100) / totalBytes).toInt().coerceIn(0, 100)
            } else {
                0
            }
    }
    data object Completed : DownloadStatus
    data class Failed(val reason: String) : DownloadStatus
}

/**
 * Downloads an application package with the platform download service so the
 * transfer continues while the app is closed, and the user is told about it
 * through the system notification shade.
 */
internal class UpdateDownloader(private val context: Context) {

    private val manager: DownloadManager
        get() = context.getSystemService(Context.DOWNLOAD_SERVICE) as DownloadManager

    fun start(url: String, fileName: String, title: String, description: String): Long {
        val request = DownloadManager.Request(Uri.parse(url))
            .setTitle(title)
            .setDescription(description)
            .setMimeType(APK_MIME)
            .setNotificationVisibility(
                DownloadManager.Request.VISIBILITY_VISIBLE_NOTIFY_COMPLETED,
            )
            .setAllowedOverMetered(true)
            .setAllowedOverRoaming(false)
            .setDestinationInExternalFilesDir(
                context,
                Environment.DIRECTORY_DOWNLOADS,
                fileName,
            )
        return manager.enqueue(request)
    }

    fun status(downloadId: Long): DownloadStatus {
        val query = DownloadManager.Query().setFilterById(downloadId)
        manager.query(query).use { cursor ->
            if (!cursor.moveToFirst()) {
                return DownloadStatus.Failed("Download is no longer tracked")
            }
            return when (cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS))) {
                DownloadManager.STATUS_PENDING -> DownloadStatus.Pending
                DownloadManager.STATUS_RUNNING -> {
                    val downloaded = cursor.getLong(
                        cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_BYTES_DOWNLOADED_SO_FAR),
                    )
                    val total = cursor.getLong(
                        cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_TOTAL_SIZE_BYTES),
                    )
                    DownloadStatus.Running(downloaded, total)
                }
                DownloadManager.STATUS_SUCCESSFUL -> DownloadStatus.Completed
                else -> {
                    val reason = cursor.getInt(
                        cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_REASON),
                    )
                    DownloadStatus.Failed("Download failed (reason $reason)")
                }
            }
        }
    }

    /** The downloaded package, if it finished and is still on disk. */
    fun downloadedFile(downloadId: Long): File? {
        val query = DownloadManager.Query().setFilterById(downloadId)
        manager.query(query).use { cursor ->
            if (!cursor.moveToFirst()) return null
            if (cursor.getInt(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_STATUS)) !=
                DownloadManager.STATUS_SUCCESSFUL
            ) {
                return null
            }
            val uri = cursor.getString(cursor.getColumnIndexOrThrow(DownloadManager.COLUMN_LOCAL_URI))
                ?: return null
            val path = Uri.parse(uri).path ?: return null
            val file = File(path)
            return file.takeIf { it.exists() }
        }
    }

    fun cancel(downloadId: Long) {
        manager.remove(downloadId)
    }

    companion object {
        const val APK_MIME = "application/vnd.android.package-archive"
    }
}
