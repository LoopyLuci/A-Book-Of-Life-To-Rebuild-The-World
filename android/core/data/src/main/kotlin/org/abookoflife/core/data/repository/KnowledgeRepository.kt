package org.abookoflife.core.data.repository

import kotlinx.coroutines.flow.Flow
import org.abookoflife.core.data.content.ImportResult
import org.abookoflife.core.model.Bookmark
import org.abookoflife.core.model.Domain
import org.abookoflife.core.model.Entry
import org.abookoflife.core.model.EntrySummary
import org.abookoflife.core.model.SearchFilters
import org.abookoflife.core.model.SearchResults

interface KnowledgeRepository {

    suspend fun ensureContentImported(force: Boolean = false): ImportResult

    suspend fun reindex(): ImportResult

    fun observeKbVersion(): Flow<String?>

    fun observeEntryCount(): Flow<Int>

    fun observeDomainCount(): Flow<Int>

    fun observeVerifiedCount(): Flow<Int>

    fun observeDomains(): Flow<List<Domain>>

    fun observeDomain(slug: String): Flow<Domain?>

    fun observeAllEntries(): Flow<List<EntrySummary>>

    fun observeEntriesByDomain(slug: String): Flow<List<EntrySummary>>

    suspend fun fieldTested(limit: Int = 6): List<EntrySummary>

    suspend fun entry(id: String): Entry?

    suspend fun entryIdBySlug(slug: String): String?

    fun observeEntry(id: String): Flow<Entry?>

    suspend fun summaries(ids: List<String>): List<EntrySummary>

    fun observeSummaries(ids: List<String>): Flow<List<EntrySummary>>

    fun observeBookmarks(): Flow<List<Bookmark>>

    fun observeIsBookmarked(entryId: String): Flow<Boolean>

    suspend fun setBookmarked(entryId: String, bookmarked: Boolean)

    fun observeMostRecentEntryId(): Flow<String?>

    fun observeProgress(entryId: String): Flow<Float>

    suspend fun recordOpened(entryId: String, scrollFraction: Float)

    suspend fun search(query: String, filters: SearchFilters = SearchFilters(), limit: Int = 40): SearchResults

    fun observeRecentQueries(limit: Int = 6): Flow<List<String>>

    suspend fun recordQuery(query: String)

    suspend fun clearRecentQueries()
}
