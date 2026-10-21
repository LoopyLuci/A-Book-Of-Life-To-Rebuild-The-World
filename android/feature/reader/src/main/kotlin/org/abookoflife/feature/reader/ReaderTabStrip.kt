package org.abookoflife.feature.reader

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.model.ReaderTab

/**
 * Horizontal strip of open reader pages, mirroring browser tabs.
 */
@Composable
fun ReaderTabStrip(
    tabs: List<ReaderTab>,
    activeEntryId: String?,
    onSelect: (String) -> Unit,
    onClose: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (tabs.isEmpty()) return

    val listState = rememberLazyListState()
    val activeIndex = tabs.indexOfFirst { it.entryId == activeEntryId }
    LaunchedEffect(activeIndex, tabs.size) {
        if (activeIndex >= 0) listState.animateScrollToItem(activeIndex)
    }

    LazyRow(
        state = listState,
        modifier = modifier.fillMaxWidth(),
        contentPadding = PaddingValues(horizontal = 12.dp, vertical = 4.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        items(tabs, key = { it.entryId }) { tab ->
            TabPill(
                tab = tab,
                selected = tab.entryId == activeEntryId,
                onSelect = { onSelect(tab.entryId) },
                onClose = { onClose(tab.entryId) },
            )
        }
    }
}

@Composable
private fun TabPill(
    tab: ReaderTab,
    selected: Boolean,
    onSelect: () -> Unit,
    onClose: () -> Unit,
) {
    Surface(
        shape = RoundedCornerShape(50),
        color = if (selected) {
            MaterialTheme.colorScheme.secondaryContainer
        } else {
            MaterialTheme.colorScheme.surfaceVariant
        },
        contentColor = if (selected) {
            MaterialTheme.colorScheme.onSecondaryContainer
        } else {
            MaterialTheme.colorScheme.onSurfaceVariant
        },
    ) {
        Row(
            modifier = Modifier
                .clickable(role = Role.Tab, onClick = onSelect)
                .padding(start = 14.dp, end = 4.dp, top = 2.dp, bottom = 2.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Text(
                text = tab.title,
                style = MaterialTheme.typography.labelLarge,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                modifier = Modifier.widthIn(max = 160.dp),
            )
            IconButton(
                onClick = onClose,
                modifier = Modifier.size(36.dp),
            ) {
                Icon(
                    imageVector = Icons.Outlined.Close,
                    contentDescription = stringResource(R.string.action_close_tab),
                    modifier = Modifier.size(18.dp),
                )
            }
        }
    }
}
