package org.abookoflife.core.data.repository

import android.content.Context
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext
import org.abookoflife.core.common.AppDispatchers
import org.abookoflife.core.data.R
import org.abookoflife.core.data.update.DownloadStatus
import org.abookoflife.core.data.update.ApkInstaller
import org.abookoflife.core.data.update.GitHubReleaseClient
import org.abookoflife.core.data.update.ReleaseInfo
import org.abookoflife.core.data.update.UpdateCheckResult
import org.abookoflife.core.data.update.UpdateDownloader
import org.abookoflife.core.data.update.UpdateStateStore
import org.abookoflife.core.data.update.VersionCompare
import java.io.File
import java.net.URI

@Singleton
class DefaultAppUpdateRepository @Inject constructor(
    @ApplicationContext private val context: Context,
    private val dispatchers: AppDispatchers,
) : AppUpdateRepository {

    private val client: GitHubReleaseClient by lazy {
        GitHubReleaseClient(
            owner = context.getString(R.string.update_repo_owner),
            repository = context.getString(R.string.update_repo_name),
        )
    }

    private val downloader: UpdateDownloader by lazy { UpdateDownloader(context) }
    private val stateStore: UpdateStateStore by lazy { UpdateStateStore(context) }

    override fun currentVersion(): String =
        runCatching {
            context.packageManager.getPackageInfo(context.packageName, 0).versionName
        }.getOrNull() ?: "0.0.0"

    override suspend fun checkForUpdate(): UpdateCheckResult = withContext(dispatchers.io) {
        try {
            val release = client.latestRelease()
            if (release.draft) {
                return@withContext UpdateCheckResult.Failed("No published release is available")
            }
            val asset = release.assets.firstOrNull { asset ->
                asset.name.endsWith(".apk", ignoreCase = true) &&
                    asset.browserDownloadUrl.isNotBlank()
            }
            if (asset == null) {
                return@withContext UpdateCheckResult.Failed("The latest release has no package")
            }
            val downloadUri = runCatching { URI(asset.browserDownloadUrl) }.getOrNull()
            val expectedPath = "/${context.getString(R.string.update_repo_owner)}/" +
                "${context.getString(R.string.update_repo_name)}/releases/download/"
            if (downloadUri?.scheme != "https" ||
                downloadUri.host != "github.com" ||
                downloadUri.userInfo != null ||
                downloadUri.port !in setOf(-1, 443) ||
                downloadUri.path?.startsWith(expectedPath) != true
            ) {
                return@withContext UpdateCheckResult.Failed(
                    "The release package URL is not from the configured GitHub repository",
                )
            }
            val info = ReleaseInfo(
                tag = release.tagName,
                name = release.name?.takeIf { it.isNotBlank() } ?: release.tagName,
                notes = release.body.orEmpty(),
                apkUrl = asset.browserDownloadUrl,
                apkSizeBytes = asset.size,
                publishedAt = release.publishedAt.orEmpty(),
            )
            val current = currentVersion()
            if (VersionCompare.isNewer(info.tag, current)) {
                UpdateCheckResult.Available(info)
            } else {
                UpdateCheckResult.UpToDate(current, info.tag)
            }
        } catch (error: Exception) {
            UpdateCheckResult.Failed(
                error.message?.takeIf { it.isNotBlank() } ?: "Could not reach the release service",
            )
        }
    }

    override suspend fun startDownload(
        release: ReleaseInfo,
        installWhenDownloaded: Boolean,
    ): Long =
        withContext(dispatchers.io) {
            val fileName = "abook-of-life-${release.tag.removePrefix("v")}.apk"
            val id = downloader.start(
                url = release.apkUrl,
                fileName = fileName,
                title = context.getString(R.string.update_download_title),
                description = context.getString(R.string.update_download_description),
            )
            stateStore.downloadId = id
            stateStore.releaseTag = release.tag
            stateStore.installWhenDownloaded = installWhenDownloaded
            id
        }

    override suspend fun downloadStatus(downloadId: Long): DownloadStatus =
        withContext(dispatchers.io) { downloader.status(downloadId) }

    override suspend fun downloadedPackage(downloadId: Long): File? =
        withContext(dispatchers.io) { downloader.downloadedFile(downloadId) }

    override fun isValidUpdatePackage(file: File): Boolean =
        ApkInstaller.isValidUpdate(context, file)

    override fun cancelDownload(downloadId: Long) {
        downloader.cancel(downloadId)
        stateStore.clear()
    }

    override fun pendingDownloadId(): Long = stateStore.downloadId

    override fun pendingReleaseTag(): String = stateStore.releaseTag

    override fun clearPendingDownload() {
        stateStore.clear()
    }
}
