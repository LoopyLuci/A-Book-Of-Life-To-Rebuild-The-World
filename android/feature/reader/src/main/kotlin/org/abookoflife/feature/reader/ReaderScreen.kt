package org.abookoflife.feature.reader

import android.content.Context
import android.content.Intent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.Share
import androidx.compose.material3.AssistChip
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.abookoflife.core.common.TextUtils
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.designsystem.component.DifficultyBadge
import org.abookoflife.core.designsystem.component.LoadingState
import org.abookoflife.core.designsystem.component.MessageState
import org.abookoflife.core.designsystem.component.SafetyBadge
import org.abookoflife.core.designsystem.component.SectionHeader
import org.abookoflife.core.designsystem.component.VerificationBadge
import org.abookoflife.core.model.Entry

@Composable
fun ReaderRoute(
    onBack: () -> Unit,
    onEntryClick: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: ReaderViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    val context = LocalContext.current
    ReaderScreen(
        state = state,
        onBack = onBack,
        onEntryClick = onEntryClick,
        onToggleBookmark = viewModel::toggleBookmark,
        onShare = { shareEntry(context, viewModel.shareText(), viewModel.shareSubject()) },
        onScroll = viewModel::onScroll,
        modifier = modifier,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ReaderScreen(
    state: ReaderUiState,
    onBack: () -> Unit,
    onEntryClick: (String) -> Unit,
    onToggleBookmark: () -> Unit,
    onShare: () -> Unit,
    onScroll: (Float) -> Unit,
    modifier: Modifier = Modifier,
) {
    Scaffold(
        modifier = modifier.fillMaxSize(),
        contentWindowInsets = WindowInsets(0.dp),
        topBar = {
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

            else -> ReaderContent(
                entry = state.entry,
                domainTitle = state.domainTitle,
                prerequisites = state.prerequisites,
                related = state.related,
                serif = state.serif,
                onEntryClick = onEntryClick,
                onScroll = onScroll,
                contentPadding = padding,
            )
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun ReaderContent(
    entry: Entry,
    domainTitle: String,
    prerequisites: List<org.abookoflife.core.model.EntrySummary>,
    related: List<org.abookoflife.core.model.EntrySummary>,
    serif: Boolean,
    onEntryClick: (String) -> Unit,
    onScroll: (Float) -> Unit,
    contentPadding: PaddingValues,
) {
    val listState = rememberLazyListState()

    LaunchedEffect(listState) {
        snapshotFlow {
            listState.firstVisibleItemIndex to listState.layoutInfo.totalItemsCount
        }.collect { (index, total) ->
            if (total > 0) onScroll(index.toFloat() / total)
        }
    }

    val bodyFamily = if (serif) FontFamily.Serif else FontFamily.SansSerif
    val bodyStyle = MaterialTheme.typography.bodyLarge.copy(fontFamily = bodyFamily)
    val readingMinutes = remember(entry.body) { TextUtils.estimateReadingMinutes(entry.body) }

    LazyColumn(
        state = listState,
        modifier = Modifier
            .fillMaxSize()
            .padding(contentPadding),
        contentPadding = PaddingValues(start = 20.dp, end = 20.dp, top = 8.dp, bottom = 48.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                if (domainTitle.isNotBlank()) {
                    Text(
                        text = domainTitle.uppercase(),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
                Text(
                    text = entry.title,
                    style = MaterialTheme.typography.headlineMedium,
                    color = MaterialTheme.colorScheme.onBackground,
                )
            }
        }

        item {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                DifficultyBadge(entry.difficulty)
                SafetyBadge(entry.safety)
                VerificationBadge(entry.verification.status)
                Text(
                    text = stringResource(R.string.reading_time, readingMinutes),
                    style = MaterialTheme.typography.labelMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    modifier = Modifier.padding(vertical = 4.dp),
                )
            }
        }

        val timeToComplete = entry.timeToComplete
        if (!timeToComplete.isNullOrBlank()) {
            item {
                MetaLine(label = stringResource(R.string.time_to_complete), value = timeToComplete)
            }
        }

        if (prerequisites.isNotEmpty()) {
            item { SectionHeader(title = stringResource(R.string.prerequisites)) }
            item {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    prerequisites.forEach { summary ->
                        AssistChip(
                            onClick = { onEntryClick(summary.id) },
                            label = { Text(summary.title) },
                        )
                    }
                }
            }
        }

        if (entry.materialsRequired.isNotEmpty() || entry.toolsRequired.isNotEmpty()) {
            item { SectionHeader(title = stringResource(R.string.materials)) }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    entry.materialsRequired.forEach { BulletLine(it) }
                    entry.toolsRequired.forEach { BulletLine(it) }
                }
            }
        }

        item { HorizontalDivider() }

        item {
            MarkdownText(markdown = entry.body, bodyStyle = bodyStyle)
        }

        if (related.isNotEmpty()) {
            item { HorizontalDivider() }
            item { SectionHeader(title = stringResource(R.string.related)) }
            item {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    related.forEach { summary ->
                        AssistChip(
                            onClick = { onEntryClick(summary.id) },
                            label = { Text(summary.title) },
                        )
                    }
                }
            }
        }

        item {
            VerificationPanel(entry)
        }

        if (entry.sources.isNotEmpty()) {
            item { SectionHeader(title = stringResource(R.string.sources)) }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    entry.sources.forEach { source ->
                        Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(
                                text = source.title,
                                style = MaterialTheme.typography.bodyMedium,
                                fontWeight = FontWeight.Medium,
                            )
                            val details = listOfNotNull(
                                source.author?.takeIf { it.isNotBlank() },
                                source.year?.takeIf { it > 0 }?.toString(),
                                source.license?.takeIf { it.isNotBlank() },
                            ).joinToString(" · ")
                            if (details.isNotBlank()) {
                                Text(
                                    text = details,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                                )
                            }
                            source.url?.takeIf { it.isNotBlank() }?.let { url ->
                                Text(
                                    text = url,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.primary,
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MetaLine(label: String, value: String) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(
            text = "$label: ",
            style = MaterialTheme.typography.labelLarge,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Text(text = value, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun BulletLine(text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(text = "•", color = MaterialTheme.colorScheme.primary)
        Text(text = text, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun VerificationPanel(entry: Entry) {
    val verification = entry.verification
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = RoundedCornerShape(16.dp),
        modifier = Modifier.fillMaxWidth(),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Outlined.CheckCircle,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                Text(
                    text = stringResource(R.string.verification),
                    style = MaterialTheme.typography.titleSmall,
                )
                VerificationBadge(verification.status)
            }
            verification.testedBy?.takeIf { it.isNotBlank() }?.let { testedBy ->
                Text(
                    text = stringResource(R.string.verified_by, testedBy),
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
            verification.location?.takeIf { it.isNotBlank() }?.let { location ->
                Text(
                    text = stringResource(R.string.tested_in, location),
                    style = MaterialTheme.typography.bodyMedium,
                )
            }
            if (verification.reviewers.isNotEmpty()) {
                Text(
                    text = verification.reviewers.joinToString(", "),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            verification.notes?.takeIf { it.isNotBlank() }?.let { notes ->
                Text(
                    text = notes,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            Spacer(Modifier.height(2.dp))
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
