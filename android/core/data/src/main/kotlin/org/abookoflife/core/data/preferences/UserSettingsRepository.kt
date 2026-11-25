package org.abookoflife.core.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.floatPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import org.abookoflife.core.model.ColorPalette
import org.abookoflife.core.model.ThemeMode
import org.abookoflife.core.model.UpdatePolicy
import org.abookoflife.core.model.UserSettings
import javax.inject.Inject
import javax.inject.Singleton

private val Context.settingsDataStore: DataStore<Preferences> by preferencesDataStore(name = "settings")

interface UserSettingsRepository {
    val settings: Flow<UserSettings>
    suspend fun setThemeMode(mode: ThemeMode)
    suspend fun setDynamicColor(enabled: Boolean)
    suspend fun setPalette(palette: ColorPalette)
    suspend fun setFontScale(scale: Float)
    suspend fun setSerif(enabled: Boolean)
    suspend fun setUpdatePolicy(policy: UpdatePolicy)
}

@Singleton
class DefaultUserSettingsRepository @Inject constructor(
    @ApplicationContext context: Context,
) : UserSettingsRepository {

    private val dataStore = context.settingsDataStore

    override val settings: Flow<UserSettings> = dataStore.data.map { prefs ->
        UserSettings(
            themeMode = ThemeMode.fromId(prefs[KEY_THEME_MODE]),
            dynamicColor = prefs[KEY_DYNAMIC_COLOR] ?: true,
            palette = ColorPalette.fromId(prefs[KEY_PALETTE]),
            fontScale = prefs[KEY_FONT_SCALE] ?: 1.0f,
            serif = prefs[KEY_SERIF] ?: false,
            updatePolicy = UpdatePolicy.fromId(prefs[KEY_UPDATE_POLICY]),
        )
    }

    override suspend fun setThemeMode(mode: ThemeMode) {
        dataStore.edit { it[KEY_THEME_MODE] = mode.name }
    }

    override suspend fun setDynamicColor(enabled: Boolean) {
        dataStore.edit { it[KEY_DYNAMIC_COLOR] = enabled }
    }

    override suspend fun setPalette(palette: ColorPalette) {
        dataStore.edit { it[KEY_PALETTE] = palette.name }
    }

    override suspend fun setFontScale(scale: Float) {
        dataStore.edit { it[KEY_FONT_SCALE] = scale.coerceIn(0.85f, 1.5f) }
    }

    override suspend fun setSerif(enabled: Boolean) {
        dataStore.edit { it[KEY_SERIF] = enabled }
    }

    override suspend fun setUpdatePolicy(policy: UpdatePolicy) {
        dataStore.edit { it[KEY_UPDATE_POLICY] = policy.name }
    }

    private companion object {
        val KEY_THEME_MODE = stringPreferencesKey("theme_mode")
        val KEY_DYNAMIC_COLOR = booleanPreferencesKey("dynamic_color")
        val KEY_PALETTE = stringPreferencesKey("color_palette")
        val KEY_FONT_SCALE = floatPreferencesKey("font_scale")
        val KEY_SERIF = booleanPreferencesKey("serif")
        val KEY_UPDATE_POLICY = stringPreferencesKey("update_policy")
    }
}
