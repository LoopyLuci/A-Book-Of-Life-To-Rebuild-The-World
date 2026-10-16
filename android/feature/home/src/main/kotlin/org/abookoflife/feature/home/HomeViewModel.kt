package org.abookoflife.feature.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.abookoflife.core.data.repository.KnowledgeRepository
import org.abookoflife.core.model.Domain
import org.abookoflife.core.model.EntrySummary
import javax.inject.Inject

data class ContinueReading(val entry: EntrySummary, val progress: Float)

data class HomeUiState(
    val domains: List<Domain> = emptyList(),
    val continueReading: ContinueReading? = null,
    val fieldTested: List<EntrySummary> = emptyList(),
    val entryCount: Int = 0,
    val domainCount: Int = 0,
    val verifiedCount: Int = 0,
    val isLoading: Boolean = true,
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val repository: KnowledgeRepository,
) : ViewModel() {

    private val continueReading = MutableStateFlow<ContinueReading?>(null)
    private val fieldTested = MutableStateFlow<List<EntrySummary>>(emptyList())

    private val counts = combine(
        repository.observeEntryCount(),
        repository.observeDomainCount(),
        repository.observeVerifiedCount(),
    ) { entries, domains, verified -> Triple(entries, domains, verified) }

    val state: StateFlow<HomeUiState> = combine(
        repository.observeDomains(),
        counts,
        fieldTested,
        continueReading,
    ) { domains, counts, field, recent ->
        HomeUiState(
            domains = domains,
            continueReading = recent,
            fieldTested = field,
            entryCount = counts.first,
            domainCount = counts.second,
            verifiedCount = counts.third,
            isLoading = false,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = HomeUiState(),
    )

    init {
        viewModelScope.launch {
            fieldTested.value = repository.fieldTested(FIELD_TESTED_LIMIT)
        }
        viewModelScope.launch {
            repository.observeMostRecentEntryId().collectLatest { id ->
                if (id == null) {
                    continueReading.value = null
                    return@collectLatest
                }
                val summary = repository.summaries(listOf(id)).firstOrNull()
                if (summary == null) {
                    continueReading.value = null
                    return@collectLatest
                }
                continueReading.value = ContinueReading(summary, 0f)
                repository.observeProgress(id).collect { progress ->
                    continueReading.value = ContinueReading(summary, progress)
                }
            }
        }
    }

    private companion object {
        const val FIELD_TESTED_LIMIT = 6
    }
}
