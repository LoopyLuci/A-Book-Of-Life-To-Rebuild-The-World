package org.abookoflife.feature.reader

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListState
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.OpenInNew
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.AssistChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import org.abookoflife.core.common.TextUtils
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.designsystem.component.DifficultyBadge
import org.abookoflife.core.designsystem.component.SafetyBadge
import org.abookoflife.core.designsystem.component.SectionHeader
import org.abookoflife.core.designsystem.component.VerificationBadge
import org.abookoflife.core.model.CostTier
import org.abookoflife.core.model.Entry
import org.abookoflife.core.model.EntrySummary
import org.abookoflife.core.model.Source

/**
 * Shared renderer for a full knowledge-base entry.
 *
 * Used by the full-screen reader and by the half-height preview sheet so both
 * always show identical, accurate content.
 */
@OptIn(ExperimentalLayoutApi::class)
@Composable
fun EntryDocument(
    entry: Entry,
    domainTitle: String,
    prerequisites: List<EntrySummary>,
    related: List<EntrySummary>,
    serif: Boolean,
    onOpenEntry: (String) -> Unit,
    onSourceClick: (Source) -> Unit,
    onLinkClick: (String) -> Unit = {},
    modifier: Modifier = Modifier,
    listState: LazyListState = rememberLazyListState(),
    onScroll: (Float) -> Unit = {},
) {
    val currentOnScroll by rememberUpdatedState(onScroll)
    LaunchedEffect(listState) {
        snapshotFlow {
            listState.firstVisibleItemIndex to listState.layoutInfo.totalItemsCount
        }.collect { (index, total) ->
            if (total > 0) currentOnScroll(index.toFloat() / total)
        }
    }

    val bodyFamily = if (serif) FontFamily.Serif else FontFamily.SansSerif
    val bodyStyle = MaterialTheme.typography.bodyLarge.copy(fontFamily = bodyFamily)
    val readingMinutes = remember(entry.body) { TextUtils.estimateReadingMinutes(entry.body) }

    LazyColumn(
        state = listState,
        modifier = modifier.fillMaxSize(),
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
        entry.expectedYield?.takeIf { it.isNotBlank() }?.let { value ->
            item { MetaBlock(label = stringResource(R.string.expected_yield), value = value) }
        }
        entry.season?.takeIf { it.isNotBlank() }?.let { value ->
            item { MetaBlock(label = stringResource(R.string.season), value = value) }
        }
        entry.storage?.takeIf { it.isNotBlank() }?.let { value ->
            item { MetaBlock(label = stringResource(R.string.storage), value = value) }
        }
        if (entry.cost != CostTier.UNKNOWN) {
            item {
                val costLabel = when (entry.cost) {
                    CostTier.LOW -> stringResource(R.string.cost_low)
                    CostTier.MEDIUM -> stringResource(R.string.cost_medium)
                    CostTier.HIGH -> stringResource(R.string.cost_high)
                    CostTier.UNKNOWN -> stringResource(R.string.cost)
                }
                MetaLine(label = stringResource(R.string.cost), value = costLabel)
            }
        }
        if (entry.regions.isNotEmpty()) {
            val regions = entry.regions.joinToString(", ") { region ->
                region.replaceFirstChar { it.uppercase() }
            }
            item { MetaLine(label = stringResource(R.string.applies_to), value = regions) }
        }

        if (entry.tags.isNotEmpty()) {
            item {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(
                        text = stringResource(R.string.tags).uppercase(),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        fontWeight = FontWeight.SemiBold,
                    )
                    FlowRow(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        entry.tags.forEach { tag -> TagPill(tag) }
                    }
                }
            }
        }

        if (prerequisites.isNotEmpty()) {
            item { SectionHeader(title = stringResource(R.string.prerequisites)) }
            item {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    prerequisites.forEach { summary ->
                        AssistChip(
                            onClick = { onOpenEntry(summary.id) },
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
                    if (entry.materialsRequired.isNotEmpty()) {
                        Text(
                            text = stringResource(R.string.materials_label).uppercase(),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.SemiBold,
                        )
                        entry.materialsRequired.forEach { BulletLine(it) }
                    }
                    if (entry.toolsRequired.isNotEmpty()) {
                        Spacer(Modifier.height(4.dp))
                        Text(
                            text = stringResource(R.string.tools_label).uppercase(),
                            style = MaterialTheme.typography.labelMedium,
                            color = MaterialTheme.colorScheme.primary,
                            fontWeight = FontWeight.SemiBold,
                        )
                        entry.toolsRequired.forEach { BulletLine(it) }
                    }
                }
            }
        }

        if (entry.hazards.isNotEmpty()) {
            item { SectionHeader(title = stringResource(R.string.key_hazards)) }
            item {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    entry.hazards.forEach { HazardLine(it) }
                }
            }
        }

        item { HorizontalDivider() }

        item {
            MarkdownText(
                markdown = entry.body,
                bodyStyle = bodyStyle,
                onLinkClick = onLinkClick,
            )
        }

        if (related.isNotEmpty()) {
            item { HorizontalDivider() }
            item { SectionHeader(title = stringResource(R.string.related)) }
            item {
                FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    related.forEach { summary ->
                        AssistChip(
                            onClick = { onOpenEntry(summary.id) },
                            label = { Text(summary.title) },
                        )
                    }
                }
            }
        }

        item { VerificationPanel(entry) }

        if (entry.sources.isNotEmpty()) {
            item { SectionHeader(title = stringResource(R.string.sources)) }
            items(entry.sources.size) { index ->
                SourceRow(
                    source = entry.sources[index],
                    onClick = { onSourceClick(entry.sources[index]) },
                )
            }
        }
    }
}

@Composable
private fun SourceRow(source: Source, onClick: () -> Unit) {
    val hasUrl = source.url?.startsWith("http") == true
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f),
        shape = RoundedCornerShape(12.dp),
        modifier = Modifier
            .fillMaxWidth()
            .clickable(role = Role.Button, onClick = onClick),
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 14.dp, vertical = 12.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.spacedBy(2.dp),
            ) {
                Text(
                    text = source.title,
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
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
                Text(
                    text = source.url?.takeIf { hasUrl }
                        ?: stringResource(R.string.source_search_hint),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.primary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Icon(
                imageVector = if (hasUrl) Icons.Outlined.OpenInNew else Icons.Outlined.Search,
                contentDescription = stringResource(
                    if (hasUrl) R.string.source_open else R.string.source_search,
                ),
                modifier = Modifier.size(18.dp),
                tint = MaterialTheme.colorScheme.primary,
            )
        }
    }
}

@Composable
private fun TagPill(tag: String) {
    Surface(
        color = MaterialTheme.colorScheme.secondaryContainer,
        contentColor = MaterialTheme.colorScheme.onSecondaryContainer,
        shape = RoundedCornerShape(50),
    ) {
        Text(
            text = "#$tag",
            style = MaterialTheme.typography.labelSmall,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 4.dp),
        )
    }
}

@Composable
private fun HazardLine(text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(
            text = "!",
            color = MaterialTheme.colorScheme.error,
            fontWeight = FontWeight.Bold,
        )
        Text(text = text, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun MetaBlock(label: String, value: String) {
    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
        Text(
            text = label.uppercase(),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            fontWeight = FontWeight.SemiBold,
        )
        Text(text = value, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
internal fun MetaLine(label: String, value: String) {
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
internal fun BulletLine(text: String) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(text = "•", color = MaterialTheme.colorScheme.primary)
        Text(text = text, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
internal fun VerificationPanel(entry: Entry) {
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
