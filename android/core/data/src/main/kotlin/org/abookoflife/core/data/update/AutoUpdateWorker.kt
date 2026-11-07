package org.abookoflife.core.data.update

import android.content.Context
import android.util.Log
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.abookoflife.core.common.AppDispatchers
import org.abookoflife.core.data.preferences.DefaultUserSettingsRepository
import org.abookoflife.core.data.repository.DefaultAppUpdateRepository
import org.abookoflife.core.model.UpdatePolicy

class AutoUpdateWorker(
    appContext: Context,
    workerParams: WorkerParameters,
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        return try {
            runUpdateCheck()
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Exception) {
            Log.e(TAG, "Automatic update check failed", error)
            if (runAttemptCount == 0) UpdateNotifications.checkFailed(applicationContext)
            Result.retry()
        }
    }

    private suspend fun runUpdateCheck(): Result {
        val settings = DefaultUserSettingsRepository(applicationContext)
        val policy = settings.settings.first().updatePolicy
        if (policy == UpdatePolicy.MANUAL) return Result.success()

        val repository = DefaultAppUpdateRepository(
            applicationContext,
            AppDispatchers.default(),
        )
        val pendingDownloadId = repository.pendingDownloadId()
        if (pendingDownloadId != 0L &&
            !VersionCompare.isNewer(repository.pendingReleaseTag(), repository.currentVersion())
        ) {
            repository.cancelDownload(pendingDownloadId)
        }

        return when (val result = repository.checkForUpdate()) {
            is UpdateCheckResult.Failed -> {
                if (runAttemptCount == 0) UpdateNotifications.checkFailed(applicationContext)
                Result.retry()
            }
            is UpdateCheckResult.UpToDate -> Result.success()
            is UpdateCheckResult.Available -> processAvailable(repository, policy, result.release)
        }
    }

    private suspend fun processAvailable(
        repository: DefaultAppUpdateRepository,
        policy: UpdatePolicy,
        release: ReleaseInfo,
    ): Result {
        if (policy == UpdatePolicy.AUTO_CHECK) {
            val stateStore = UpdateStateStore(applicationContext)
            if (stateStore.lastNotifiedTag != release.tag &&
                UpdateNotifications.available(applicationContext, release.tag)
            ) {
                stateStore.lastNotifiedTag = release.tag
            }
            return Result.success()
        }

        return downloadMutex.withLock {
            val currentPolicy = DefaultUserSettingsRepository(applicationContext)
                .settings
                .first()
                .updatePolicy
            if (currentPolicy == UpdatePolicy.MANUAL) return@withLock Result.success()

            val pendingDownloadId = repository.pendingDownloadId()
            if (pendingDownloadId != 0L) {
                if (repository.pendingReleaseTag() == release.tag) {
                    when (repository.downloadStatus(pendingDownloadId)) {
                        DownloadStatus.Pending,
                        is DownloadStatus.Running,
                        -> {
                            UpdateStateStore(applicationContext).installWhenDownloaded =
                                currentPolicy == UpdatePolicy.AUTO_DOWNLOAD_AND_INSTALL
                            return@withLock Result.success()
                        }
                        DownloadStatus.Completed -> {
                            val stateStore = UpdateStateStore(applicationContext)
                            val shouldRequestInstall =
                                currentPolicy == UpdatePolicy.AUTO_DOWNLOAD_AND_INSTALL
                            stateStore.installWhenDownloaded = shouldRequestInstall
                            if (shouldRequestInstall && stateStore.installPromptedTag != release.tag) {
                                val apk = repository.downloadedPackage(pendingDownloadId)
                                if (apk != null) {
                                    if (!ApkInstaller.isValidUpdate(applicationContext, apk)) {
                                        UpdateNotifications.invalidPackage(applicationContext)
                                        repository.cancelDownload(pendingDownloadId)
                                        return@withLock Result.success()
                                    }
                                    val installIntent = if (ApkInstaller.canInstall(applicationContext)) {
                                        ApkInstaller.installIntent(applicationContext, apk)
                                    } else {
                                        ApkInstaller.permissionIntent(applicationContext)
                                    }
                                    if (UpdateNotifications.downloaded(
                                            applicationContext,
                                            release.tag,
                                            installIntent,
                                        )
                                    ) {
                                        stateStore.installPromptedTag = release.tag
                                    }
                                }
                            }
                            return@withLock Result.success()
                        }
                        is DownloadStatus.Failed -> repository.clearPendingDownload()
                    }
                } else {
                    repository.cancelDownload(pendingDownloadId)
                }
            }

            repository.startDownload(
                release = release,
                installWhenDownloaded = currentPolicy == UpdatePolicy.AUTO_DOWNLOAD_AND_INSTALL,
            )
            Result.success()
        }
    }

    private companion object {
        const val TAG = "AutoUpdateWorker"
        val downloadMutex = Mutex()
    }
}
