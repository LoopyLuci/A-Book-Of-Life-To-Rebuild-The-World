package org.abookoflife.app.ui

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.Density
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import org.abookoflife.app.ContentStatus
import org.abookoflife.app.MainViewModel
import org.abookoflife.core.designsystem.R
import org.abookoflife.core.designsystem.component.LoadingState
import org.abookoflife.core.designsystem.component.MessageState
import org.abookoflife.core.designsystem.theme.AbookTheme
import org.abookoflife.core.model.ThemeMode

@Composable
fun AbookAppRoot(viewModel: MainViewModel = hiltViewModel()) {
    val state by viewModel.state.collectAsStateWithLifecycle()

    val darkTheme = when (state.settings.themeMode) {
        ThemeMode.SYSTEM -> isSystemInDarkTheme()
        ThemeMode.LIGHT -> false
        ThemeMode.DARK -> true
    }

    AbookTheme(darkTheme = darkTheme, dynamicColor = state.settings.dynamicColor) {
        val current = LocalDensity.current
        CompositionLocalProvider(
            LocalDensity provides Density(current.density, state.settings.fontScale),
        ) {
            Surface(
                modifier = Modifier.fillMaxSize(),
                color = MaterialTheme.colorScheme.background,
            ) {
                when (val content = state.content) {
                    ContentStatus.Loading -> LoadingState(
                        message = stringResource(R.string.content_importing),
                    )

                    is ContentStatus.Error -> MessageState(
                        title = stringResource(R.string.error_generic),
                        body = content.message,
                        icon = Icons.Outlined.ErrorOutline,
                        actionLabel = stringResource(R.string.action_retry),
                        onAction = viewModel::retry,
                    )

                    ContentStatus.Ready -> AbookNavHost()
                }
            }
        }
    }
}
