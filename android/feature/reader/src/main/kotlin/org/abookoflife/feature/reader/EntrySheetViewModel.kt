package org.abookoflife.feature.reader

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import org.abookoflife.core.data.repository.KnowledgeRepository
import org.abookoflife.core.model.Entry
import org.abookoflife.core.model.EntrySummary
import javax.inject.Inject

data class EntrySheetUiState(
    val entry: Entry? = null,
    val domainTitle: String = "",
    val prerequisites: List<EntrySummary> = emptyList(),
    val related: List<EntrySummary> = emptyList(),
    val loading: Boolean = true,
    val missing: Boolean = false,
)

@HiltViewModel
class EntrySheetViewModel @Inject constructor(
    private val repository: KnowledgeRepository,
) : ViewModel() {

    private val _state = MutableStateFlow(EntrySheetUiState())
    val state: StateFlow<EntrySheetUiState> = _state.asStateFlow()

    private var loader: Job? = null

    suspend fun entryIdForSlug(slug: String): String? = repository.entryIdBySlug(slug)

    fun load(entryId: String) {
        loader?.cancel()
        loader = viewModelScope.launch {
            _state.value = EntrySheetUiState(loading = true)
            val entry = repository.entry(entryId)
            if (entry == null) {
                _state.value = EntrySheetUiState(loading = false, missing = true)
                return@launch
            }
            val domains = repository.observeDomains().first()
            val domainTitle = domains.firstOrNull { it.slug == entry.domain }?.title.orEmpty()
            _state.value = EntrySheetUiState(
                entry = entry,
                domainTitle = domainTitle,
                prerequisites = repository.summaries(entry.prerequisites),
                related = repository.summaries(entry.links),
                loading = false,
            )
        }
    }
}
