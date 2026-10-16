package org.abookoflife.feature.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.abookoflife.core.data.repository.KnowledgeRepository
import org.abookoflife.core.model.Difficulty
import org.abookoflife.core.model.Domain
import org.abookoflife.core.model.SafetyLevel
import org.abookoflife.core.model.SearchFilters
import org.abookoflife.core.model.SearchHit
import org.abookoflife.core.model.SearchResults
import javax.inject.Inject

data class SearchUiState(
    val query: String = "",
    val filters: SearchFilters = SearchFilters(),
    val results: List<SearchHit> = emptyList(),
    val recent: List<String> = emptyList(),
    val domains: List<Domain> = emptyList(),
    val isSearching: Boolean = false,
    val tookMillis: Long = 0,
    val hasSearched: Boolean = false,
)

private sealed interface SearchOutcome {
    data object Idle : SearchOutcome
    data object Searching : SearchOutcome
    data class Done(val results: SearchResults) : SearchOutcome
}

private data class QueryContext(
    val query: String,
    val filters: SearchFilters,
    val recent: List<String>,
    val domains: List<Domain>,
)

@OptIn(FlowPreview::class, ExperimentalCoroutinesApi::class)
@HiltViewModel
class SearchViewModel @Inject constructor(
    private val repository: KnowledgeRepository,
) : ViewModel() {

    private val _query = MutableStateFlow("")
    val query: StateFlow<String> = _query.asStateFlow()

    private val _filters = MutableStateFlow(SearchFilters())
    val filters: StateFlow<SearchFilters> = _filters.asStateFlow()

    private val outcome: Flow<SearchOutcome> = combine(
        _query.debounce(SEARCH_DEBOUNCE_MS).distinctUntilChanged(),
        _filters,
    ) { query, filters -> query.trim() to filters }
        .flatMapLatest { (query, filters) ->
            if (query.isEmpty()) {
                flowOf<SearchOutcome>(SearchOutcome.Idle)
            } else {
                flow {
                    emit(SearchOutcome.Searching)
                    emit(SearchOutcome.Done(repository.search(query, filters)))
                }
            }
        }

    private val context: Flow<QueryContext> = combine(
        _query,
        _filters,
        repository.observeRecentQueries(),
        repository.observeDomains(),
    ) { query, filters, recent, domains ->
        QueryContext(query, filters, recent, domains)
    }

    val state: StateFlow<SearchUiState> = combine(outcome, context) { outcome, context ->
        when (outcome) {
            SearchOutcome.Idle -> SearchUiState(
                query = context.query,
                filters = context.filters,
                recent = context.recent,
                domains = context.domains,
                hasSearched = false,
            )
            SearchOutcome.Searching -> SearchUiState(
                query = context.query,
                filters = context.filters,
                recent = context.recent,
                domains = context.domains,
                isSearching = true,
                hasSearched = true,
            )
            is SearchOutcome.Done -> SearchUiState(
                query = context.query,
                filters = context.filters,
                results = outcome.results.hits,
                recent = context.recent,
                domains = context.domains,
                isSearching = false,
                tookMillis = outcome.results.tookMillis,
                hasSearched = true,
            )
        }
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = SearchUiState(),
    )

    fun onQueryChange(value: String) {
        _query.value = value
    }

    fun clearQuery() {
        _query.value = ""
    }

    fun toggleDomain(slug: String) {
        _filters.value = _filters.value.toggleDomain(slug)
    }

    fun toggleDifficulty(difficulty: Difficulty) {
        _filters.value = _filters.value.toggleDifficulty(difficulty)
    }

    fun toggleSafety(safety: SafetyLevel) {
        _filters.value = _filters.value.toggleSafety(safety)
    }

    fun clearFilters() {
        _filters.value = SearchFilters()
    }

    fun onQuerySubmitted() {
        record(_query.value)
    }

    fun onRecentSelected(value: String) {
        _query.value = value
        record(value)
    }

    fun onResultSelected() {
        record(_query.value)
    }

    fun clearRecent() {
        viewModelScope.launch { repository.clearRecentQueries() }
    }

    private fun record(value: String) {
        viewModelScope.launch { repository.recordQuery(value) }
    }

    private companion object {
        const val SEARCH_DEBOUNCE_MS = 220L
    }
}
