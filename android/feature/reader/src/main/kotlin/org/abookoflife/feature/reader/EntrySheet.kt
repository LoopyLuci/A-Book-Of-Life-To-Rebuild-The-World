package org.abookoflife.feature.reader

import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Tab
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.listSaver
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import kotlinx.coroutines.launch
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.designsystem.component.LoadingState
import org.abookoflife.core.designsystem.component.MessageState
import org.abookoflife.core.model.ReaderTab

/**
 * Half-height preview of an entry.
 *
 * Opens at the half-expanded state, can be dragged up to full height and
 * scrolled like a normal page, dragged back down to dismiss, or promoted to a
 * persistent reader tab.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EntrySheet(
    entryId: String,
    serif: Boolean,
    onDismiss: () -> Unit,
    onOpenTab: (ReaderTab) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: EntrySheetViewModel = hiltViewModel(),
) {
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false)
    var history by rememberSaveable(
        stateSaver = listSaver<List<String>, String>(
            save = { it },
            restore = { it },
        ),
    ) { mutableStateOf(listOf(entryId)) }
    val currentId = history.last()
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    LaunchedEffect(currentId) { viewModel.load(currentId) }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        modifier = modifier,
        dragHandle = { BottomSheetDefaults.DragHandle() },
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .fillMaxHeight(0.94f),
        ) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                if (history.size > 1) {
                    IconButton(onClick = { history = history.dropLast(1) }) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                            contentDescription = stringResource(R.string.action_back),
                        )
                    }
                } else {
                    Spacer(Modifier.size(48.dp))
                }

                Text(
                    text = state.entry?.title.orEmpty(),
                    style = MaterialTheme.typography.titleMedium,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier
                        .weight(1f)
                        .padding(horizontal = 4.dp),
                )

                IconButton(
                    onClick = {
                        state.entry?.let { entry ->
                            onOpenTab(ReaderTab(entry.id, entry.title, entry.domain))
                        }
                    },
                    enabled = state.entry != null,
                ) {
                    Icon(
                        imageVector = Icons.Outlined.Tab,
                        contentDescription = stringResource(R.string.action_open_in_new_tab),
                    )
                }

                IconButton(onClick = onDismiss) {
                    Icon(
                        imageVector = Icons.Outlined.Close,
                        contentDescription = stringResource(R.string.action_close),
                    )
                }
            }

            HorizontalDivider()

            val entry = state.entry
            when {
                state.loading -> LoadingState(
                    message = stringResource(R.string.preview_loading),
                    modifier = Modifier.weight(1f),
                )

                state.missing || entry == null -> MessageState(
                    title = stringResource(R.string.error_entry_missing),
                    body = stringResource(R.string.error_generic),
                    icon = Icons.Outlined.ErrorOutline,
                    modifier = Modifier.weight(1f),
                    actionLabel = stringResource(R.string.action_close),
                    onAction = onDismiss,
                )

                else -> EntryDocument(
                    entry = entry,
                    domainTitle = state.domainTitle,
                    prerequisites = state.prerequisites,
                    related = state.related,
                    serif = serif,
                    onOpenEntry = { id -> history = history + id },
                    onSourceClick = { openSource(context, it) },
                    onLinkClick = { raw ->
                        val target = raw.trim()
                        when {
                            target.startsWith("http://") || target.startsWith("https://") ->
                                openUrl(context, target)

                            target.startsWith("#") || target.isBlank() -> Unit

                            else -> scope.launch {
                                viewModel.entryIdForSlug(markdownLinkSlug(target))?.let { id ->
                                    history = history + id
                                }
                            }
                        }
                    },
                    modifier = Modifier.weight(1f),
                    listState = remember(currentId) { LazyListState() },
                )
            }
        }
    }
}
