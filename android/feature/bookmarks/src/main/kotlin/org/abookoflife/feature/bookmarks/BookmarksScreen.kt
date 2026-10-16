package org.abookoflife.feature.bookmarks

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.designsystem.component.EntryCard
import org.abookoflife.core.designsystem.component.MessageState

@Composable
fun BookmarksRoute(
    onEntryClick: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: BookmarksViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    BookmarksScreen(
        state = state,
        onEntryClick = onEntryClick,
        onRemove = viewModel::remove,
        modifier = modifier,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun BookmarksScreen(
    state: BookmarksUiState,
    onEntryClick: (String) -> Unit,
    onRemove: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets(0.dp),
        topBar = {
            TopAppBar(
                title = { Text(stringResource(R.string.nav_bookmarks)) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                ),
            )
        },
    ) { padding ->
        if (state.bookmarks.isEmpty() && !state.isLoading) {
            MessageState(
                title = stringResource(R.string.no_bookmarks_title),
                body = stringResource(R.string.no_bookmarks_body),
                icon = Icons.Outlined.BookmarkBorder,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
            )
            return@Scaffold
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 32.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            items(state.bookmarks, key = { it.entry.id }) { bookmark ->
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    EntryCard(
                        summary = bookmark.entry,
                        domainLabel = state.domainTitles[bookmark.entry.domain].orEmpty(),
                        onClick = { onEntryClick(bookmark.entry.id) },
                    )
                    TextButton(
                        onClick = { onRemove(bookmark.entry.id) },
                        modifier = Modifier.align(Alignment.End),
                    ) {
                        Text(stringResource(R.string.remove_bookmark))
                    }
                }
            }
        }
    }
}
