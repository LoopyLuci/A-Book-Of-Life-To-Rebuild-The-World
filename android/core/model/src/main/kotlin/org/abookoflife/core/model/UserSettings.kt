package org.abookoflife.core.model

enum class ThemeMode {
    SYSTEM,
    LIGHT,
    DARK,
    ;

    companion object {
        fun fromId(raw: String?): ThemeMode =
            entries.firstOrNull { it.name == raw?.uppercase() } ?: SYSTEM
    }
}

enum class ColorPalette {
    FOREST,
    OCEAN,
    SUNSET,
    LILAC,
    GRAPHITE,
    ;

    companion object {
        fun fromId(raw: String?): ColorPalette =
            entries.firstOrNull { it.name == raw?.uppercase() } ?: FOREST
    }
}

data class UserSettings(
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val dynamicColor: Boolean = true,
    val palette: ColorPalette = ColorPalette.FOREST,
    val fontScale: Float = 1.0f,
    val serif: Boolean = false,
)
