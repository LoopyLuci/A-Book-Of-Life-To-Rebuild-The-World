package org.abookoflife.core.data.repository

import java.io.File
import org.abookoflife.core.data.update.DownloadStatus
import org.abookoflife.core.data.update.ReleaseInfo
import org.abookoflife.core.data.update.UpdateCheckResult

/**
 * Finds newer published builds and downloads them in the background.
 *
 * The app is offline-first: nothing happens until a reader asks for it, and
 * every failure is reported rather than thrown.
 */
interface AppUpdateRepository {

    /** The version name of the installed build. */
    fun currentVersion(): String

    /** Asks the release service whether a newer build exists. */
    suspend fun checkForUpdate(): UpdateCheckResult

    /** Starts a background download of the given release. */
    suspend fun startDownload(release: ReleaseInfo): Long

    /** Progress of a running or finished download. */
    suspend fun downloadStatus(downloadId: Long): DownloadStatus

    /** The downloaded package on disk, or null if it is not ready. */
    suspend fun downloadedPackage(downloadId: Long): File?

    /** Stops a running download. */
    fun cancelDownload(downloadId: Long)

    /** The download started earlier in this session, or 0 when there is none. */
    fun pendingDownloadId(): Long

    /** The release tag of the download started earlier in this session. */
    fun pendingReleaseTag(): String

    /** Forgets the recorded download. */
    fun clearPendingDownload()
}
