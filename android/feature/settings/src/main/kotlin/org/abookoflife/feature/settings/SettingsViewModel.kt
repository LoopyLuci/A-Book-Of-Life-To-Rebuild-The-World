package org.abookoflife.feature.settings

import android.content.Context
import android.content.Intent
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import java.io.File
import javax.inject.Inject
import kotlinx.coroutines.delay
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.abookoflife.core.data.preferences.UserSettingsRepository
import org.abookoflife.core.data.repository.AppUpdateRepository
import org.abookoflife.core.data.repository.KnowledgeRepository
import org.abookoflife.core.data.update.ApkInstaller
import org.abookoflife.core.data.update.AutoUpdateScheduler
import org.abookoflife.core.data.update.DownloadStatus
import org.abookoflife.core.data.update.ReleaseInfo
import org.abookoflife.core.data.update.UpdateCheckResult
import org.abookoflife.core.data.update.VersionCompare
import org.abookoflife.core.model.ColorPalette
import org.abookoflife.core.model.ThemeMode
import org.abookoflife.core.model.UpdatePolicy
import org.abookoflife.core.model.UserSettings

/** What the app knows about a newer published release. */
sealed interface UpdateState {
    /** Nothing has been requested yet. */
    data object Idle : UpdateState

    /** The release service is being asked. */
    data object Checking : UpdateState

    /** The installed build is current. */
    data class UpToDate(val latestTag: String) : UpdateState

    /** A newer build exists and can be fetched. */
    data class Available(val release: ReleaseInfo) : UpdateState

    /** The package is being fetched in the background. */
    data class Downloading(val percent: Int, val releaseTag: String) : UpdateState

    /** The package is on disk and waiting for the reader to confirm. */
    data class ReadyToInstall(val releaseTag: String, val apk: File) : UpdateState

    /** The check or the download did not work. */
    data class Failed(val reason: String) : UpdateState
}

data class SettingsUiState(
    val settings: UserSettings = UserSettings(),
    val kbVersion: String = "—",
    val entryCount: Int = 0,
    val isReindexing: Boolean = false,
    val reindexTick: Int = 0,
    val updateState: UpdateState = UpdateState.Idle,
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: UserSettingsRepository,
    private val knowledgeRepository: KnowledgeRepository,
    private val updateRepository: AppUpdateRepository,
    private val autoUpdateScheduler: AutoUpdateScheduler,
) : ViewModel() {

    private val reindexState = MutableStateFlow(ReindexState())
    private val updateState = MutableStateFlow<UpdateState>(UpdateState.Idle)

    val state: StateFlow<SettingsUiState> = combine(
        settingsRepository.settings,
        knowledgeRepository.observeKbVersion(),
        knowledgeRepository.observeEntryCount(),
        reindexState,
        updateState,
    ) { settings, version, count, reindex, update ->
        SettingsUiState(
            settings = settings,
            kbVersion = version ?: "—",
            entryCount = count,
            isReindexing = reindex.running,
            reindexTick = reindex.completed,
            updateState = update,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = SettingsUiState(),
    )

    fun setTheme(mode: ThemeMode) = launch { settingsRepository.setThemeMode(mode) }

    fun setDynamicColor(enabled: Boolean) = launch { settingsRepository.setDynamicColor(enabled) }

    fun setPalette(palette: ColorPalette) = launch { settingsRepository.setPalette(palette) }

    fun setFontScale(scale: Float) = launch { settingsRepository.setFontScale(scale) }

    fun setSerif(enabled: Boolean) = launch { settingsRepository.setSerif(enabled) }

    fun setUpdatePolicy(policy: UpdatePolicy) {
        viewModelScope.launch {
            settingsRepository.setUpdatePolicy(policy)
            autoUpdateScheduler.setPolicy(policy)
        }
    }

    fun reindex() {
        viewModelScope.launch {
            reindexState.value = ReindexState(running = true, completed = reindexState.value.completed)
            knowledgeRepository.reindex()
            reindexState.value = ReindexState(running = false, completed = reindexState.value.completed + 1)
        }
    }

    /** Looks for a newer published release. */
    fun checkForUpdate() {
        viewModelScope.launch {
            updateState.value = UpdateState.Checking
            updateState.value = when (val result = updateRepository.checkForUpdate()) {
                is UpdateCheckResult.Available -> UpdateState.Available(result.release)
                is UpdateCheckResult.UpToDate -> UpdateState.UpToDate(result.latestTag)
                is UpdateCheckResult.Failed -> UpdateState.Failed(result.reason)
            }
        }
    }

    /**
     * Fetches the release package in the background. The transfer continues
     * after the app is closed; the platform download service reports back when
     * it is finished.
     */
    fun downloadUpdate(release: ReleaseInfo) {
        viewModelScope.launch {
            updateState.value = UpdateState.Downloading(0, release.tag)
            try {
                val activeDownloadId = updateRepository.pendingDownloadId()
                if (activeDownloadId != 0L) {
                    if (updateRepository.pendingReleaseTag() == release.tag) {
                        pollDownload(activeDownloadId, release.tag)
                        return@launch
                    }
                    updateRepository.cancelDownload(activeDownloadId)
                }
                val downloadId = updateRepository.startDownload(
                    release = release,
                    installWhenDownloaded = true,
                )
                pollDownload(downloadId, release.tag)
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (error: Exception) {
                updateState.value = UpdateState.Failed(
                    error.message?.takeIf { it.isNotBlank() } ?: "Could not start the update download",
                )
            }
        }
    }

    /** Picks up a download that was started earlier, for example before a restart. */
    fun resumePendingDownload() {
        val downloadId = updateRepository.pendingDownloadId()
        if (downloadId == 0L) return
        val tag = updateRepository.pendingReleaseTag()
        if (!VersionCompare.isNewer(tag, updateRepository.currentVersion())) {
            updateRepository.cancelDownload(downloadId)
            updateState.value = UpdateState.Idle
            return
        }
        viewModelScope.launch {
            try {
                pollDownload(downloadId, tag)
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (error: Exception) {
                updateState.value = UpdateState.Failed(
                    error.message?.takeIf { it.isNotBlank() } ?: "Could not read update download status",
                )
            }
        }
    }

    /** Stops a running download and forgets it. */
    fun cancelUpdate() {
        val downloadId = updateRepository.pendingDownloadId()
        if (downloadId != 0L) {
            updateRepository.cancelDownload(downloadId)
        }
        updateState.value = UpdateState.Idle
    }

    private suspend fun pollDownload(downloadId: Long, releaseTag: String) {
        while (true) {
            when (val status = updateRepository.downloadStatus(downloadId)) {
                is DownloadStatus.Pending -> updateState.value =
                    UpdateState.Downloading(0, releaseTag)

                is DownloadStatus.Running -> updateState.value =
                    UpdateState.Downloading(status.percent, releaseTag)

                is DownloadStatus.Completed -> {
                    val apk = updateRepository.downloadedPackage(downloadId)
                    updateState.value = if (apk != null &&
                        updateRepository.isValidUpdatePackage(apk)
                    ) {
                        UpdateState.ReadyToInstall(releaseTag, apk)
                    } else {
                        UpdateState.Failed("The downloaded package could not be validated")
                    }
                    return
                }

                is DownloadStatus.Failed -> {
                    updateState.value = UpdateState.Failed(status.reason)
                    updateRepository.clearPendingDownload()
                    return
                }
            }
            delay(POLL_INTERVAL_MS)
        }
    }

    private fun launch(block: suspend () -> Unit) {
        viewModelScope.launch { block() }
    }

    private data class ReindexState(val running: Boolean = false, val completed: Int = 0)

    private companion object {
        const val POLL_INTERVAL_MS = 700L
    }
}

/** Whether the reader has allowed this app to install packages. */
fun canInstallPackages(context: Context): Boolean = ApkInstaller.canInstall(context)

/** The screen where the reader grants permission to install packages. */
fun installPermissionIntent(context: Context): Intent = ApkInstaller.permissionIntent(context)

/** The intent that opens the platform installer for a downloaded package. */
fun installPackageIntent(context: Context, apk: File): Intent =
    ApkInstaller.installIntent(context, apk)
