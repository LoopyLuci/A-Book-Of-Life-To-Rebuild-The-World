package org.abookoflife.app

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
import org.abookoflife.core.model.UserSettings
import javax.inject.Inject

sealed interface ContentStatus {
    data object Loading : ContentStatus
    data object Ready : ContentStatus
    data class Error(val message: String) : ContentStatus
}

data class AppUiState(
    val settings: UserSettings = UserSettings(),
    val content: ContentStatus = ContentStatus.Loading,
)

@HiltViewModel
class MainViewModel @Inject constructor(
    private val knowledgeRepository: KnowledgeRepository,
    settingsRepository: UserSettingsRepository,
) : ViewModel() {

    private val content = MutableStateFlow<ContentStatus>(ContentStatus.Loading)

    val state: StateFlow<AppUiState> = combine(settingsRepository.settings, content) { settings, status ->
        AppUiState(settings = settings, content = status)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = AppUiState(),
    )

    init {
        importContent()
    }

    fun retry() = importContent()

    private fun importContent() {
        viewModelScope.launch {
            content.value = ContentStatus.Loading
            runCatching { knowledgeRepository.ensureContentImported() }
                .onSuccess { content.value = ContentStatus.Ready }
                .onFailure { throwable ->
                    content.value = ContentStatus.Error(throwable.message ?: "import-failed")
                }
        }
    }
}
