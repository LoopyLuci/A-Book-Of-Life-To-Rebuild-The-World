package org.abookoflife.feature.reader

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.launch
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.designsystem.component.LoadingState
import org.abookoflife.core.designsystem.component.MessageState
import org.abookoflife.core.model.ReaderTab
import org.abookoflife.core.model.Source

@Composable
fun ReaderRoute(
    entryId: String,
    onBack: () -> Unit,
    onSelectTab: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ReaderViewModel = hiltViewModel(),
    tabsViewModel: ReaderTabsViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val tabs by tabsViewModel.tabs.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var previewEntryId by rememberSaveable { mutableStateOf<String?>(null) }

    val onLinkClick: (String) -> Unit = { raw ->
        val target = raw.trim()
        when {
            target.startsWith("http://") || target.startsWith("https://") ->
                openUrl(context, target)

            target.startsWith("#") || target.isBlank() -> Unit

            else -> scope.launch {
                viewModel.entryIdForSlug(markdownLinkSlug(target))?.let { previewEntryId = it }
            }
        }
    }

    val entry = state.entry
    LaunchedEffect(entry?.id, entry?.title, entry?.domain) {
        if (entry != null) {
            tabsViewModel.touch(ReaderTab(entry.id, entry.title, entry.domain))
        }
    }

    ReaderScreen(
        state = state,
        tabs = tabs,
        activeEntryId = entryId,
        onBack = onBack,
        onSelectTab = onSelectTab,
        onCloseTab = { id ->
            tabsViewModel.close(id)
            if (id == entryId) {
                val next = tabs.filterNot { it.entryId == id }.lastOrNull()
                if (next != null) onSelectTab(next.entryId) else onBack()
            }
        },
        onToggleBookmark = viewModel::toggleBookmark,
        onShare = { shareEntry(context, viewModel.shareText(), viewModel.shareSubject()) },
        onOpenEntry = { previewEntryId = it },
        onSourceClick = { openSource(context, it) },
        onLinkClick = onLinkClick,
        onScroll = viewModel::onScroll,
        modifier = modifier,
    )

    previewEntryId?.let { id ->
        EntrySheet(
            entryId = id,
            serif = state.serif,
            onDismiss = { previewEntryId = null },
            onOpenTab = { tab ->
                tabsViewModel.touch(tab)
                previewEntryId = null
                onSelectTab(tab.entryId)
            },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReaderScreen(
    state: ReaderUiState,
    tabs: List<ReaderTab>,
    activeEntryId: String,
    onBack: () -> Unit,
    onSelectTab: (String) -> Unit,
    onCloseTab: (String) -> Unit,
    onToggleBookmark: () -> Unit,
    onShare: () -> Unit,
    onOpenEntry: (String) -> Unit,
    onSourceClick: (Source) -> Unit,
    onLinkClick: (String) -> Unit,
    onScroll: (Float) -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets(0.dp),
        topBar = {
            Column {
                TopAppBar(
                    title = {
                        Text(
                            text = state.entry?.title ?: state.domainTitle,
                            maxLines = 1,
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = onBack) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                                contentDescription = stringResource(R.string.action_back),
                            )
                        }
                    },
                    actions = {
                        IconButton(onClick = onToggleBookmark) {
                            Icon(
                                imageVector = if (state.isBookmarked) {
                                    Icons.Filled.Bookmark
                                } else {
                                    Icons.Outlined.BookmarkBorder
                                },
                                contentDescription = stringResource(
                                    if (state.isBookmarked) R.string.action_bookmarked else R.string.action_bookmark,
                                ),
                            )
                        }
                        IconButton(onClick = onShare) {
                            Icon(
                                imageVector = Icons.Outlined.Share,
                                contentDescription = stringResource(R.string.action_share),
                            )
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(
                        containerColor = MaterialTheme.colorScheme.background,
                    ),
                )
                ReaderTabStrip(
                    tabs = tabs,
                    activeEntryId = activeEntryId,
                    onSelect = onSelectTab,
                    onClose = onCloseTab,
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        },
    ) { padding ->
        when {
            state.isLoading -> LoadingState(
                message = stringResource(R.string.loading),
                modifier = Modifier.padding(padding),
            )

            state.missing || state.entry == null -> MessageState(
                title = stringResource(R.string.error_entry_missing),
                body = stringResource(R.string.error_generic),
                icon = Icons.Outlined.ErrorOutline,
                modifier = Modifier.padding(padding),
                actionLabel = stringResource(R.string.action_back),
                onAction = onBack,
            )

            else -> EntryDocument(
                entry = state.entry,
                domainTitle = state.domainTitle,
                prerequisites = state.prerequisites,
                related = state.related,
                serif = state.serif,
                onOpenEntry = onOpenEntry,
                onSourceClick = onSourceClick,
                onLinkClick = onLinkClick,
                onScroll = onScroll,
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding),
            )
        }
    }
}

private fun shareEntry(context: Context, text: String, subject: String) {
    if (text.isBlank()) return
    val intent = Intent(Intent.ACTION_SEND).apply {
        type = "text/plain"
        putExtra(Intent.EXTRA_SUBJECT, subject)
        putExtra(Intent.EXTRA_TEXT, text)
    }
    context.startActivity(Intent.createChooser(intent, null))
}
