package org.abookoflife.feature.bookmarks

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import org.abookoflife.core.data.repository.KnowledgeRepository
import org.abookoflife.core.model.Bookmark
import javax.inject.Inject

data class BookmarksUiState(
    val bookmarks: List<Bookmark> = emptyList(),
    val domainTitles: Map<String, String> = emptyMap(),
    val isLoading: Boolean = true,
)

@HiltViewModel
class BookmarksViewModel @Inject constructor(
    private val repository: KnowledgeRepository,
) : ViewModel() {

    val state: StateFlow<BookmarksUiState> = combine(
        repository.observeBookmarks(),
        repository.observeDomains(),
    ) { bookmarks, domains ->
        BookmarksUiState(
            bookmarks = bookmarks,
            domainTitles = domains.associate { it.slug to it.title },
            isLoading = false,
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(5_000),
        initialValue = BookmarksUiState(),
    )

    fun remove(entryId: String) {
        viewModelScope.launch { repository.setBookmarked(entryId, false) }
    }
}
