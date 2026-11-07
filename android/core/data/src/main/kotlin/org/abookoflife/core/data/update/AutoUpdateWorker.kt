package org.abookoflife.core.data.update

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import kotlinx.coroutines.flow.first
import org.abookoflife.core.common.AppDispatchers
import org.abookoflife.core.data.preferences.DefaultUserSettingsRepository
import org.abookoflife.core.data.repository.DefaultAppUpdateRepository
import org.abookoflife.core.model.UpdatePolicy

class AutoUpdateWorker(
    appContext: Context,
    workerParams: WorkerParameters,
) : CoroutineWorker(appContext, workerParams) {

    override suspend fun doWork(): Result {
        val policy = DefaultUserSettingsRepository(applicationContext).settings.first().updatePolicy
        if (policy == UpdatePolicy.MANUAL) return Result.success()

        val repository = DefaultAppUpdateRepository(
            applicationContext,
            AppDispatchers.default(),
        )
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

        val pendingDownloadId = repository.pendingDownloadId()
        if (pendingDownloadId != 0L) {
            if (repository.pendingReleaseTag() == release.tag) {
                when (repository.downloadStatus(pendingDownloadId)) {
                    DownloadStatus.Pending,
                    is DownloadStatus.Running,
                    -> {
                        UpdateStateStore(applicationContext).installWhenDownloaded =
                            policy == UpdatePolicy.AUTO_DOWNLOAD_AND_INSTALL
                        return Result.success()
                    }
                    DownloadStatus.Completed -> {
                        val stateStore = UpdateStateStore(applicationContext)
                        val shouldRequestInstall =
                            policy == UpdatePolicy.AUTO_DOWNLOAD_AND_INSTALL
                        stateStore.installWhenDownloaded = shouldRequestInstall
                        if (shouldRequestInstall && stateStore.installPromptedTag != release.tag) {
                            val apk = repository.downloadedPackage(pendingDownloadId)
                            if (apk != null) {
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
                        return Result.success()
                    }
                    is DownloadStatus.Failed -> repository.clearPendingDownload()
                }
            } else {
                repository.cancelDownload(pendingDownloadId)
            }
        }

        repository.startDownload(
            release = release,
            installWhenDownloaded = policy == UpdatePolicy.AUTO_DOWNLOAD_AND_INSTALL,
        )
        return Result.success()
    }
}
