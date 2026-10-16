package org.abookoflife.feature.reader

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.abookoflife.core.data.preferences.UserSettingsRepository
import org.abookoflife.core.data.repository.KnowledgeRepository
import org.abookoflife.core.model.Entry
import org.abookoflife.core.model.EntrySummary
import javax.inject.Inject

data class Extras(
    val prerequisites: List<EntrySummary> = emptyList(),
    val related: List<EntrySummary> = emptyList(),
    val loaded: Boolean = false,
)

data class ReaderUiState(
    val entry: Entry? = null,
    val domainTitle: String = "",
    val isBookmarked: Boolean = false,
    val prerequisites: List<EntrySummary> = emptyList(),
    val related: List<EntrySummary> = emptyList(),
    val isLoading: Boolean = true,
    val missing: Boolean = false,
    val serif: Boolean = false,
)

@OptIn(FlowPreview::class)
@HiltViewModel
class ReaderViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val repository: KnowledgeRepository,
    settingsRepository: UserSettingsRepository,
) : ViewModel() {

    private val entryId: String = checkNotNull(savedStateHandle["entryId"])

    private val extras = MutableStateFlow(Extras())
    private val scroll = MutableStateFlow(0f)

    val state: StateFlow<ReaderUiState> = combine(
        repository.observeEntry(entryId),
        repository.observeIsBookmarked(entryId),
        repository.observeDomains(),
        extras,
        settingsRepository.settings,
    ) { entry, bookmarked, domains, extra, settings ->
        ReaderUiState(
            entry = entry,
            domainTitle = domains.firstOrNull { it.slug == entry?.domain }?.title.orEmpty(),
            isBookmarked = bookmarked,
            prerequisites = extra.prerequisites,
            related = extra.related,
            isLoading = !extra.loaded,
            missing = extra.loaded && entry == null,
            serif = settings.serif,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = ReaderUiState(),
    )

    init {
        viewModelScope.launch {
            repository.observeEntry(entryId).collectLatest { entry ->
                if (entry == null) {
                    extras.value = Extras(loaded = true)
                    return@collectLatest
                }
                val prerequisites = repository.summaries(entry.prerequisites)
                val related = repository.summaries(entry.links)
                extras.value = Extras(prerequisites = prerequisites, related = related, loaded = true)
            }
        }
        viewModelScope.launch {
            scroll.debounce(600L).collect { fraction ->
                repository.recordOpened(entryId, fraction)
            }
        }
    }

    fun onScroll(fraction: Float) {
        scroll.value = fraction.coerceIn(0f, 1f)
    }

    fun toggleBookmark() {
        val bookmarked = state.value.isBookmarked
        viewModelScope.launch { repository.setBookmarked(entryId, !bookmarked) }
    }

    fun shareText(): String {
        val entry = state.value.entry ?: return ""
        return buildString {
            append("# ")
            append(entry.title)
            append("\n\n")
            append(entry.body.trim())
            append("\n\n— ")
            append(entry.domain)
        }
    }

    fun shareSubject(): String = state.value.entry?.title.orEmpty()
}
