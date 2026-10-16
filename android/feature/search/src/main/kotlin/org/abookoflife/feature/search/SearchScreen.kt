package org.abookoflife.feature.search

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.SearchOff
import androidx.compose.material3.AssistChip
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.designsystem.component.EntryCard
import org.abookoflife.core.designsystem.component.LoadingState
import org.abookoflife.core.designsystem.component.MessageState
import org.abookoflife.core.designsystem.component.SectionHeader
import org.abookoflife.core.designsystem.component.difficultyLabel
import org.abookoflife.core.designsystem.component.safetyLabel
import org.abookoflife.core.model.Difficulty
import org.abookoflife.core.model.SafetyLevel

@Composable
fun SearchRoute(
    onEntryClick: (String) -> Unit,
    onBack: (() -> Unit)?,
    modifier: Modifier = Modifier,
    viewModel: SearchViewModel = hiltViewModel(),
) {
    val state by viewModel.state.collectAsStateWithLifecycle()
    SearchScreen(
        state = state,
        onQueryChange = viewModel::onQueryChange,
        onQuerySubmitted = viewModel::onQuerySubmitted,
        onClearQuery = viewModel::clearQuery,
        onToggleDomain = viewModel::toggleDomain,
        onToggleDifficulty = viewModel::toggleDifficulty,
        onToggleSafety = viewModel::toggleSafety,
        onClearFilters = viewModel::clearFilters,
        onRecentSelected = viewModel::onRecentSelected,
        onClearRecent = viewModel::clearRecent,
        onResultSelected = { entryId ->
            viewModel.onResultSelected()
            onEntryClick(entryId)
        },
        onBack = onBack,
        modifier = modifier,
    )
}

@Composable
fun SearchScreen(
    state: SearchUiState,
    onQueryChange: (String) -> Unit,
    onQuerySubmitted: () -> Unit,
    onClearQuery: () -> Unit,
    onToggleDomain: (String) -> Unit,
    onToggleDifficulty: (Difficulty) -> Unit,
    onToggleSafety: (SafetyLevel) -> Unit,
    onClearFilters: () -> Unit,
    onRecentSelected: (String) -> Unit,
    onClearRecent: () -> Unit,
    onResultSelected: (String) -> Unit,
    onBack: (() -> Unit)?,
    modifier: Modifier = Modifier,
) {
    val focusRequester = remember { FocusRequester() }
    val keyboard = LocalSoftwareKeyboardController.current
    val domainTitles = remember(state.domains) { state.domains.associate { it.slug to it.title } }

    LaunchedEffect(Unit) { focusRequester.requestFocus() }

    Column(modifier = modifier.fillMaxSize()) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(start = 4.dp, end = 12.dp, top = 8.dp, bottom = 4.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            if (onBack != null) {
                IconButton(onClick = onBack) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Outlined.ArrowBack,
                        contentDescription = stringResource(R.string.action_back),
                    )
                }
            }
            OutlinedTextField(
                value = state.query,
                onValueChange = onQueryChange,
                modifier = Modifier
                    .weight(1f)
                    .focusRequester(focusRequester)
                    .testTag("search_input"),
                placeholder = { Text(stringResource(R.string.search_hint)) },
                singleLine = true,
                trailingIcon = {
                    if (state.query.isNotEmpty()) {
                        IconButton(onClick = onClearQuery) {
                            Icon(
                                imageVector = Icons.Outlined.Close,
                                contentDescription = stringResource(R.string.action_clear),
                            )
                        }
                    }
                },
                keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                keyboardActions = KeyboardActions(
                    onSearch = {
                        onQuerySubmitted()
                        keyboard?.hide()
                    },
                ),
            )
        }

        FilterRow(
            state = state,
            onToggleDomain = onToggleDomain,
            onToggleDifficulty = onToggleDifficulty,
            onToggleSafety = onToggleSafety,
            onClearFilters = onClearFilters,
        )

        when {
            state.query.isBlank() -> SearchIdle(
                recent = state.recent,
                onRecentSelected = onRecentSelected,
                onClearRecent = onClearRecent,
            )

            state.isSearching -> LoadingState()

            state.results.isEmpty() -> MessageState(
                title = stringResource(R.string.no_results_title),
                body = stringResource(R.string.no_results_body),
                icon = Icons.Outlined.SearchOff,
            )

            else -> LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(start = 16.dp, end = 16.dp, top = 8.dp, bottom = 32.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                item {
                    Text(
                        text = stringResource(R.string.results_count, state.results.size),
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
                items(state.results, key = { it.summary.id }) { hit ->
                    EntryCard(
                        summary = hit.summary,
                        domainLabel = domainTitles[hit.summary.domain].orEmpty(),
                        highlightText = hit.snippet,
                        onClick = { onResultSelected(hit.summary.id) },
                    )
                }
            }
        }
    }
}

@Composable
private fun FilterRow(
    state: SearchUiState,
    onToggleDomain: (String) -> Unit,
    onToggleDifficulty: (Difficulty) -> Unit,
    onToggleSafety: (SafetyLevel) -> Unit,
    onClearFilters: () -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        LazyRow(
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item {
                FilterChip(
                    selected = state.filters.domains.isEmpty(),
                    onClick = { if (state.filters.domains.isNotEmpty()) onClearFilters() },
                    label = { Text(stringResource(R.string.all)) },
                )
            }
            items(state.domains, key = { it.slug }) { domain ->
                FilterChip(
                    selected = domain.slug in state.filters.domains,
                    onClick = { onToggleDomain(domain.slug) },
                    label = { Text(domain.title) },
                )
            }
        }
        LazyRow(
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            items(Difficulty.entries.filter { it != Difficulty.UNKNOWN }, key = { "d-${it.id}" }) { difficulty ->
                FilterChip(
                    selected = difficulty in state.filters.difficulties,
                    onClick = { onToggleDifficulty(difficulty) },
                    label = { Text(difficultyLabel(difficulty)) },
                )
            }
            items(SafetyLevel.entries.filter { it != SafetyLevel.UNKNOWN }, key = { "s-${it.id}" }) { safety ->
                FilterChip(
                    selected = safety in state.filters.safety,
                    onClick = { onToggleSafety(safety) },
                    label = { Text(safetyLabel(safety)) },
                )
            }
        }
    }
}

@Composable
private fun SearchIdle(
    recent: List<String>,
    onRecentSelected: (String) -> Unit,
    onClearRecent: () -> Unit,
) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(
            text = stringResource(R.string.search_hint_title),
            style = MaterialTheme.typography.headlineSmall,
        )
        Text(
            text = stringResource(R.string.search_hint_body),
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        if (recent.isNotEmpty()) {
            SectionHeader(
                title = stringResource(R.string.recent_searches),
                actionLabel = stringResource(R.string.action_clear),
                onAction = onClearRecent,
            )
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(recent, key = { it }) { term ->
                    AssistChip(
                        onClick = { onRecentSelected(term) },
                        label = { Text(term) },
                    )
                }
            }
        }
        Spacer(Modifier.width(1.dp))
    }
}
