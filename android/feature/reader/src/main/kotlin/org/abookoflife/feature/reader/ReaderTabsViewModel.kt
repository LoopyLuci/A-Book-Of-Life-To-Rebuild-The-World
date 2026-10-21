package org.abookoflife.feature.reader

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.abookoflife.core.data.preferences.ReaderTabsRepository
import org.abookoflife.core.model.ReaderTab
import javax.inject.Inject

@HiltViewModel
class ReaderTabsViewModel @Inject constructor(
    private val repository: ReaderTabsRepository,
) : ViewModel() {

    val tabs: StateFlow<List<ReaderTab>> = repository.tabs
        .stateIn(
            scope = viewModelScope,
            started = SharingStarted.WhileSubscribed(5_000),
            initialValue = emptyList(),
        )

    fun open(tab: ReaderTab) = viewModelScope.launch { repository.open(tab) }

    /**
     * Adds [tab] when missing but keeps the existing order when it is already
     * open, so simply reading an entry does not shuffle the tab strip.
     */
    fun touch(tab: ReaderTab) = viewModelScope.launch {
        if (tabs.value.any { it.entryId == tab.entryId }) {
            repository.refresh(tab)
        } else {
            repository.open(tab)
        }
    }

    fun refresh(tab: ReaderTab) = viewModelScope.launch { repository.refresh(tab) }

    fun close(entryId: String) = viewModelScope.launch { repository.close(entryId) }

    fun closeAll() = viewModelScope.launch { repository.clear() }
}
