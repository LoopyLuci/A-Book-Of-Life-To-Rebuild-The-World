package org.abookoflife.core.designsystem.theme

import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.ColorScheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.lerp
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.platform.LocalContext
import org.abookoflife.core.model.ColorPalette

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
    surfaceTint = ForestGreen,
    inverseSurface = Ink,
    inverseOnSurface = Sand,
    inversePrimary = ForestGreenContainer,
    surfaceDim = lerp(Sand, Ink, 0.10f),
    surfaceBright = Sand,
    surfaceContainerLowest = Color(0xFFFFFFFF),
    surfaceContainerLow = lerp(Sand, Ink, 0.04f),
    surfaceContainer = lerp(Sand, Ink, 0.06f),
    surfaceContainerHigh = lerp(Sand, Ink, 0.09f),
    surfaceContainerHighest = lerp(Sand, Ink, 0.12f),
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
    surfaceTint = ForestGreenLight,
    inverseSurface = NightOnSurface,
    inverseOnSurface = NightSurface,
    inversePrimary = ForestGreenDarkContainer,
    surfaceDim = NightSurface,
    surfaceBright = lerp(NightSurface, NightOnSurface, 0.12f),
    surfaceContainerLowest = lerp(NightSurface, NightOnSurface, 0.02f),
    surfaceContainerLow = lerp(NightSurface, NightOnSurface, 0.05f),
    surfaceContainer = lerp(NightSurface, NightOnSurface, 0.08f),
    surfaceContainerHigh = lerp(NightSurface, NightOnSurface, 0.11f),
    surfaceContainerHighest = lerp(NightSurface, NightOnSurface, 0.14f),
)

private data class PaletteSeeds(
    val lightPrimary: Color,
    val darkPrimary: Color,
    val lightSecondary: Color,
    val darkSecondary: Color,
    val lightTertiary: Color,
    val darkTertiary: Color,
)

private fun seedsFor(palette: ColorPalette): PaletteSeeds = when (palette) {
    ColorPalette.FOREST -> PaletteSeeds(
        lightPrimary = ForestGreen,
        darkPrimary = ForestGreenLight,
        lightSecondary = Clay,
        darkSecondary = ClayLight,
        lightTertiary = Teal,
        darkTertiary = TealLight,
    )
    ColorPalette.OCEAN -> PaletteSeeds(
        lightPrimary = Color(0xFF1E5B75),
        darkPrimary = Color(0xFF8ECFE7),
        lightSecondary = Color(0xFF4E6076),
        darkSecondary = Color(0xFFB6C7DD),
        lightTertiary = Color(0xFF2F7E6B),
        darkTertiary = Color(0xFF8FD6C4),
    )
    ColorPalette.SUNSET -> PaletteSeeds(
        lightPrimary = Color(0xFFA6411E),
        darkPrimary = Color(0xFFFFB59C),
        lightSecondary = Color(0xFF8A5A00),
        darkSecondary = Color(0xFFF2C46B),
        lightTertiary = Color(0xFF7A2E55),
        darkTertiary = Color(0xFFEFB0CE),
    )
    ColorPalette.LILAC -> PaletteSeeds(
        lightPrimary = Color(0xFF5D4A9C),
        darkPrimary = Color(0xFFCDBDFF),
        lightSecondary = Color(0xFF8A4A6B),
        darkSecondary = Color(0xFFF3B3CF),
        lightTertiary = Color(0xFF2F6F6A),
        darkTertiary = Color(0xFF9BD5CF),
    )
    ColorPalette.GRAPHITE -> PaletteSeeds(
        lightPrimary = Color(0xFF3F4943),
        darkPrimary = Color(0xFFBFC9C1),
        lightSecondary = Color(0xFF5A5F5A),
        darkSecondary = Color(0xFFC6CCC4),
        lightTertiary = Color(0xFF4A5560),
        darkTertiary = Color(0xFFBAC5D2),
    )
}

fun palettePrimaryColor(palette: ColorPalette, dark: Boolean): Color =
    seedsFor(palette).let { if (dark) it.darkPrimary else it.lightPrimary }

private fun contrastOn(color: Color): Color =
    if (color.luminance() > 0.45f) ForestOnContainer else Sand

private fun containerFor(accent: Color, surface: Color, dark: Boolean): Color =
    lerp(surface, accent, if (dark) 0.32f else 0.20f)

private fun onContainerFor(accent: Color, dark: Boolean): Color =
    if (dark) lerp(accent, NightOnSurface, 0.55f) else lerp(accent, Ink, 0.60f)

private fun schemeFor(palette: ColorPalette, dark: Boolean): ColorScheme {
    val base = if (dark) DarkColors else LightColors
    if (palette == ColorPalette.FOREST) return base

    val seeds = seedsFor(palette)
    val surface = if (dark) NightSurface else Sand
    val primary = if (dark) seeds.darkPrimary else seeds.lightPrimary
    val secondary = if (dark) seeds.darkSecondary else seeds.lightSecondary
    val tertiary = if (dark) seeds.darkTertiary else seeds.lightTertiary

    return base.copy(
        primary = primary,
        onPrimary = contrastOn(primary),
        primaryContainer = containerFor(primary, surface, dark),
        onPrimaryContainer = onContainerFor(primary, dark),
        secondary = secondary,
        onSecondary = contrastOn(secondary),
        secondaryContainer = containerFor(secondary, surface, dark),
        onSecondaryContainer = onContainerFor(secondary, dark),
        tertiary = tertiary,
        onTertiary = contrastOn(tertiary),
        tertiaryContainer = containerFor(tertiary, surface, dark),
        onTertiaryContainer = onContainerFor(tertiary, dark),
        inversePrimary = containerFor(primary, surface, dark),
        surfaceTint = primary,
    )
}

@Composable
fun AbookTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    dynamicColor: Boolean = true,
    palette: ColorPalette = ColorPalette.FOREST,
    content: @Composable () -> Unit,
) {
    val context = LocalContext.current
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        else -> schemeFor(palette, darkTheme)
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
