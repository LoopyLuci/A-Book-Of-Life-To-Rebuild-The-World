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

data class UserSettings(
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val dynamicColor: Boolean = true,
    val fontScale: Float = 1.0f,
    val serif: Boolean = false,
)
