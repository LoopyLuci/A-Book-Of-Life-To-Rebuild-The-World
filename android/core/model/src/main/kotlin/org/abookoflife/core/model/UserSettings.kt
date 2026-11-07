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

enum class UpdatePolicy {
    MANUAL,
    AUTO_CHECK,
    AUTO_DOWNLOAD,
    AUTO_DOWNLOAD_AND_INSTALL,
    ;

    companion object {
        fun fromId(raw: String?): UpdatePolicy =
            entries.firstOrNull { it.name == raw?.uppercase() } ?: MANUAL
    }
}

data class UserSettings(
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val dynamicColor: Boolean = true,
    val palette: ColorPalette = ColorPalette.FOREST,
    val fontScale: Float = 1.0f,
    val serif: Boolean = false,
    val updatePolicy: UpdatePolicy = UpdatePolicy.MANUAL,
)
