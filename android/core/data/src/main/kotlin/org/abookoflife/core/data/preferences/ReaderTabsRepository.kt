package org.abookoflife.core.data.preferences

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import org.abookoflife.core.data.JsonCodec
import org.abookoflife.core.model.ReaderTab
import javax.inject.Inject
import javax.inject.Singleton

private val Context.readerTabsDataStore: DataStore<Preferences> by preferencesDataStore(name = "reader_tabs")

/**
 * Persists the set of pages the reader keeps open, mirroring a browser's tab strip.
 */
interface ReaderTabsRepository {
    val tabs: Flow<List<ReaderTab>>

    /** Adds [tab] (or refreshes it) and moves it to the most-recent position. */
    suspend fun open(tab: ReaderTab)

    /** Updates the title/domain of an already-open tab, if present. */
    suspend fun refresh(tab: ReaderTab)

    suspend fun close(entryId: String)

    suspend fun clear()
}

@Singleton
class DefaultReaderTabsRepository @Inject constructor(
    @ApplicationContext context: Context,
) : ReaderTabsRepository {

    private val dataStore = context.readerTabsDataStore

    override val tabs: Flow<List<ReaderTab>> = dataStore.data
        .map { prefs -> decode(prefs[KEY_TABS]).map { it.toModel() } }
        .distinctUntilChanged()

    override suspend fun open(tab: ReaderTab) {
        dataStore.edit { prefs ->
            val current = decode(prefs[KEY_TABS]).filterNot { it.entryId == tab.entryId }
            val next = (current + tab.toDto()).takeLast(MAX_TABS)
            prefs[KEY_TABS] = encode(next)
        }
    }

    override suspend fun refresh(tab: ReaderTab) {
        dataStore.edit { prefs ->
            val current = decode(prefs[KEY_TABS])
            if (current.none { it.entryId == tab.entryId }) return@edit
            val next = current.map { existing ->
                if (existing.entryId == tab.entryId) {
                    existing.copy(title = tab.title, domain = tab.domain)
                } else {
                    existing
                }
            }
            prefs[KEY_TABS] = encode(next)
        }
    }

    override suspend fun close(entryId: String) {
        dataStore.edit { prefs ->
            val next = decode(prefs[KEY_TABS]).filterNot { it.entryId == entryId }
            prefs[KEY_TABS] = encode(next)
        }
    }

    override suspend fun clear() {
        dataStore.edit { prefs -> prefs.remove(KEY_TABS) }
    }

    private fun encode(tabs: List<TabDto>): String = JsonCodec.json.encodeToString(tabs)

    private fun decode(raw: String?): List<TabDto> {
        if (raw.isNullOrBlank()) return emptyList()
        return runCatching { JsonCodec.json.decodeFromString<List<TabDto>>(raw) }
            .getOrDefault(emptyList())
    }

    @Serializable
    private data class TabDto(
        val entryId: String,
        val title: String,
        val domain: String = "",
    )

    private fun TabDto.toModel(): ReaderTab = ReaderTab(entryId, title, domain)

    private fun ReaderTab.toDto(): TabDto = TabDto(entryId, title, domain)

    private companion object {
        val KEY_TABS = stringPreferencesKey("open_tabs")
        const val MAX_TABS = 24
    }
}
