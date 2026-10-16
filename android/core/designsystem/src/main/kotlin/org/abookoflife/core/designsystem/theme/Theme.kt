package org.abookoflife.core.designsystem.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.platform.LocalContext

val LocalDarkTheme = staticCompositionLocalOf { false }

private val LightColors = lightColorScheme(
    primary = ForestGreen,
    onPrimary = Sand,
    primaryContainer = ForestGreenContainer,
    onPrimaryContainer = ForestOnContainer,
    secondary = Clay,
    onSecondary = Sand,
    secondaryContainer = ClayContainer,
    onSecondaryContainer = ClayOnContainer,
    tertiary = Teal,
    onTertiary = Sand,
    tertiaryContainer = TealContainer,
    onTertiaryContainer = ForestOnContainer,
    background = Sand,
    onBackground = Ink,
    surface = Sand,
    onSurface = Ink,
    surfaceVariant = SurfaceVariantLight,
    onSurfaceVariant = OnSurfaceVariantLight,
    outline = OutlineLight,
    outlineVariant = OutlineVariantLight,
    error = ErrorLight,
    onError = Sand,
)

private val DarkColors = darkColorScheme(
    primary = ForestGreenLight,
    onPrimary = ForestOnContainer,
    primaryContainer = ForestGreenDarkContainer,
    onPrimaryContainer = ForestGreenContainer,
    secondary = ClayLight,
    onSecondary = ClayOnContainer,
    secondaryContainer = ClayDarkContainer,
    onSecondaryContainer = ClayContainer,
    tertiary = TealLight,
    onTertiary = ForestOnContainer,
    tertiaryContainer = TealDarkContainer,
    onTertiaryContainer = TealContainer,
    background = NightSurface,
    onBackground = NightOnSurface,
    surface = NightSurface,
    onSurface = NightOnSurface,
    surfaceVariant = SurfaceVariantDark,
    onSurfaceVariant = OnSurfaceVariantDark,
    outline = OutlineDark,
    outlineVariant = OutlineVariantDark,
    error = ErrorDark,
    onError = ForestOnContainer,
)

@Composable
fun AbookTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColors
        else -> LightColors
    }

    CompositionLocalProvider(LocalDarkTheme provides darkTheme) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = AbookTypography,
            shapes = AbookShapes,
            content = content,
        )
    }
}
