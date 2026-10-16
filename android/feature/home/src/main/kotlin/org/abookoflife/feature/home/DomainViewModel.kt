package org.abookoflife.feature.home

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import org.abookoflife.core.data.repository.KnowledgeRepository
import org.abookoflife.core.model.Domain
import org.abookoflife.core.model.EntrySummary
import javax.inject.Inject

data class DomainUiState(
    val domain: Domain? = null,
    val entries: List<EntrySummary> = emptyList(),
    val isLoading: Boolean = true,
)

@HiltViewModel
class DomainViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    repository: KnowledgeRepository,
) : ViewModel() {

    private val slug: String = checkNotNull(savedStateHandle["slug"])

    val state: StateFlow<DomainUiState> = combine(
        repository.observeDomain(slug),
        repository.observeEntriesByDomain(slug),
    ) { domain, entries ->
        DomainUiState(domain = domain, entries = entries, isLoading = false)
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = DomainUiState(),
    )
}
