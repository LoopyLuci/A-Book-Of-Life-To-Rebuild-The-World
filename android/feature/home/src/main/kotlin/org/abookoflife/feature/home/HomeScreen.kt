package org.abookoflife.feature.home

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesome
import androidx.compose.material.icons.outlined.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.hilt.navigation.compose.hiltViewModel
import org.abookoflife.core.designsystem.component.DomainCard
import org.abookoflife.core.designsystem.component.EntryCard
import org.abookoflife.core.designsystem.component.SectionHeader
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.model.Domain
import org.abookoflife.core.model.EntrySummary
import androidx.compose.ui.res.stringResource

@Composable
fun HomeRoute(
    onSearchClick: () -> Unit,
    onEntryClick: (String) -> Unit,
    onDomainClick: (String) -> Unit,
    modifier: Modifier = Modifier,
    viewModel: HomeViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    HomeScreen(
        state = state,
        onSearchClick = onSearchClick,
        onEntryClick = onEntryClick,
        onDomainClick = onDomainClick,
        modifier = modifier,
    )
}

@Composable
fun HomeScreen(
    state: HomeUiState,
    onSearchClick: () -> Unit,
    onEntryClick: (String) -> Unit,
    onDomainClick: (String) -> Unit,
    modifier: Modifier = Modifier,
) {
    val domainTitles = remember(state.domains) {
        state.domains.associate { it.slug to it.title }
    }

    LazyColumn(
        modifier = modifier
            .fillMaxSize()
            .testTag("home_list"),
        contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 24.dp, bottom = 32.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        item { HomeHeader(state) }
        item { SearchTrigger(state.entryCount, onSearchClick) }

        state.continueReading?.let { continueReading ->
            item {
                SectionHeader(title = stringResource(R.string.continue_reading))
            }
            item {
                ContinueReadingCard(
                    item = continueReading,
                    domainLabel = domainTitles[continueReading.entry.domain].orEmpty(),
                    onClick = { onEntryClick(continueReading.entry.id) },
                )
            }
        }

        if (state.fieldTested.isNotEmpty()) {
            item {
                SectionHeader(
                    title = stringResource(R.string.field_tested),
                    actionLabel = null,
                )
            }
            items(state.fieldTested, key = { "ft-${it.id}" }) { entry ->
                EntryCard(
                    summary = entry,
                    domainLabel = domainTitles[entry.domain].orEmpty(),
                    onClick = { onEntryClick(entry.id) },
                )
            }
        }

        item {
            SectionHeader(title = stringResource(R.string.domains))
        }
        items(state.domains, key = { "domain-${it.slug}" }) { domain ->
            DomainCard(
                domain = domain,
                countLabel = domain.entryCount.toString(),
                onClick = { onDomainClick(domain.slug) },
            )
        }
    }
}

@Composable
private fun HomeHeader(state: HomeUiState) {
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Text(
            text = stringResource(R.string.site_name),
            style = MaterialTheme.typography.displaySmall,
            color = MaterialTheme.colorScheme.onBackground,
        )
        Text(
            text = stringResource(R.string.tagline),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        Spacer(Modifier.height(4.dp))
        Text(
            text = stringResource(R.string.library_stats, state.entryCount, state.domainCount),
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.primary,
            fontWeight = FontWeight.SemiBold,
        )
    }
}

@Composable
private fun SearchTrigger(entryCount: Int, onClick: () -> Unit) {
    Surface(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(16.dp),
        color = MaterialTheme.colorScheme.surfaceVariant,
    ) {
        Row(
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(
                imageVector = Icons.Outlined.Search,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Text(
                text = stringResource(R.string.search_placeholder, entryCount),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
    }
}

@Composable
private fun ContinueReadingCard(
    item: ContinueReading,
    domainLabel: String,
    onClick: () -> Unit,
) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.primaryContainer,
            contentColor = MaterialTheme.colorScheme.onPrimaryContainer,
        ),
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(
                    imageVector = Icons.Outlined.AutoAwesome,
                    contentDescription = null,
                    modifier = Modifier.size(18.dp),
                )
                Spacer(Modifier.width(8.dp))
                Text(
                    text = domainLabel.uppercase(),
                    style = MaterialTheme.typography.labelSmall,
                )
            }
            Text(
                text = item.entry.title,
                style = MaterialTheme.typography.titleLarge,
            )
            if (item.progress > 0f) {
                LinearProgressIndicator(
                    progress = { item.progress.coerceIn(0f, 1f) },
                    modifier = Modifier.fillMaxWidth(),
                )
            }
        }
    }
}
