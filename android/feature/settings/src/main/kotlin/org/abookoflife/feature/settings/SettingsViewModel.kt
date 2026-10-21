package org.abookoflife.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.abookoflife.core.data.preferences.UserSettingsRepository
import org.abookoflife.core.data.repository.KnowledgeRepository
import org.abookoflife.core.model.ColorPalette
import org.abookoflife.core.model.ThemeMode
import org.abookoflife.core.model.UserSettings
import javax.inject.Inject

data class SettingsUiState(
    val settings: UserSettings = UserSettings(),
    val kbVersion: String = "—",
    val entryCount: Int = 0,
    val isReindexing: Boolean = false,
    val reindexTick: Int = 0,
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsRepository: UserSettingsRepository,
    private val knowledgeRepository: KnowledgeRepository,
) : ViewModel() {

    private val reindexState = MutableStateFlow(ReindexState())

    val state: StateFlow<SettingsUiState> = combine(
        settingsRepository.settings,
        knowledgeRepository.observeKbVersion(),
        knowledgeRepository.observeEntryCount(),
        reindexState,
    ) { settings, version, count, reindex ->
        SettingsUiState(
            settings = settings,
            kbVersion = version ?: "—",
            entryCount = count,
            isReindexing = reindex.running,
            reindexTick = reindex.completed,
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

    fun reindex() {
        viewModelScope.launch {
            reindexState.value = ReindexState(running = true, completed = reindexState.value.completed)
            knowledgeRepository.reindex()
            reindexState.value = ReindexState(running = false, completed = reindexState.value.completed + 1)
        }
    }

    private fun launch(block: suspend () -> Unit) {
        viewModelScope.launch { block() }
    }

    private data class ReindexState(val running: Boolean = false, val completed: Int = 0)
}
