package org.abookoflife.core.data.repository

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import org.abookoflife.core.common.AppDispatchers
import org.abookoflife.core.data.content.ContentImporter
import org.abookoflife.core.data.content.ImportResult
import org.abookoflife.core.data.local.AbookDatabase
import org.abookoflife.core.data.local.BookmarkEntity
import org.abookoflife.core.data.local.ReadingProgressEntity
import org.abookoflife.core.data.local.RecentQueryEntity
import org.abookoflife.core.data.search.SearchEngine
import org.abookoflife.core.data.toBookmark
import org.abookoflife.core.data.toDomain
import org.abookoflife.core.data.toEntry
import org.abookoflife.core.data.toSummary
import org.abookoflife.core.model.Bookmark
import org.abookoflife.core.model.Domain
import org.abookoflife.core.model.Entry
import org.abookoflife.core.model.EntrySummary
import org.abookoflife.core.model.SearchFilters
import org.abookoflife.core.model.SearchHit
import org.abookoflife.core.model.SearchResults
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DefaultKnowledgeRepository @Inject constructor(
    private val database: AbookDatabase,
    private val importer: ContentImporter,
    private val searchEngine: SearchEngine,
    private val dispatchers: AppDispatchers,
) : KnowledgeRepository {

    private val entryDao = database.entryDao()
    private val bookmarkDao = database.bookmarkDao()
    private val progressDao = database.readingProgressDao()
    private val recentQueryDao = database.recentQueryDao()
    private val domainDao = database.domainDao()
    private val metaDao = database.metaDao()

    override suspend fun ensureContentImported(force: Boolean): ImportResult =
        importer.importIfNeeded(force)

    override suspend fun reindex(): ImportResult = importer.reindex()

    override fun observeKbVersion(): Flow<String?> =
        metaDao.observe(AbookDatabase.META_KB_VERSION)

    override fun observeEntryCount(): Flow<Int> = entryDao.observeCount()

    override fun observeDomainCount(): Flow<Int> = domainDao.observeCount()

    override fun observeVerifiedCount(): Flow<Int> = entryDao.observeVerifiedCount()

    override fun observeDomains(): Flow<List<Domain>> =
        domainDao.observeAll().map { list -> list.map { it.toDomain() } }

    override fun observeDomain(slug: String): Flow<Domain?> =
        domainDao.observeBySlug(slug).map { it?.toDomain() }

    override fun observeAllEntries(): Flow<List<EntrySummary>> =
        entryDao.observeAllSummaries().map { rows -> rows.map { it.toSummary() } }

    override fun observeEntriesByDomain(slug: String): Flow<List<EntrySummary>> =
        entryDao.observeSummariesByDomain(slug).map { rows -> rows.map { it.toSummary() } }

    override suspend fun fieldTested(limit: Int): List<EntrySummary> =
        entryDao.fieldTested(limit).map { it.toSummary() }

    override suspend fun entry(id: String): Entry? = entryDao.entry(id)?.toEntry()

    override suspend fun entryIdBySlug(slug: String): String? = entryDao.idBySlug(slug)

    override fun observeEntry(id: String): Flow<Entry?> =
        entryDao.observeEntry(id).map { it?.toEntry() }.distinctUntilChanged()

    override suspend fun summaries(ids: List<String>): List<EntrySummary> =
        if (ids.isEmpty()) emptyList() else entryDao.summariesByIds(ids).map { it.toSummary() }

    override fun observeSummaries(ids: List<String>): Flow<List<EntrySummary>> =
        if (ids.isEmpty()) {
            kotlinx.coroutines.flow.flowOf(emptyList())
        } else {
            entryDao.observeSummariesByIds(ids).map { rows -> rows.map { it.toSummary() } }
        }

    override fun observeBookmarks(): Flow<List<Bookmark>> =
        bookmarkDao.observeAll().map { rows -> rows.map { it.toBookmark() } }

    override fun observeIsBookmarked(entryId: String): Flow<Boolean> =
        bookmarkDao.observeIsBookmarked(entryId).distinctUntilChanged()

    override suspend fun setBookmarked(entryId: String, bookmarked: Boolean) {
        if (bookmarked) {
            bookmarkDao.insert(BookmarkEntity(entryId, System.currentTimeMillis()))
        } else {
            bookmarkDao.delete(entryId)
        }
    }

    override fun observeMostRecentEntryId(): Flow<String?> =
        progressDao.observeMostRecent().map { it?.entryId }.distinctUntilChanged()

    override fun observeProgress(entryId: String): Flow<Float> =
        progressDao.observeFor(entryId).map { it?.scrollFraction ?: 0f }.distinctUntilChanged()

    override suspend fun recordOpened(entryId: String, scrollFraction: Float) {
        progressDao.upsert(
            ReadingProgressEntity(
                entryId = entryId,
                lastOpenedAt = System.currentTimeMillis(),
                scrollFraction = scrollFraction,
            )
        )
    }

    override suspend fun search(
        query: String,
        filters: SearchFilters,
        limit: Int,
    ): SearchResults {
        val startedAt = System.nanoTime()
        val ranked = searchEngine.search(query, filters, limit)
        val summaries = if (ranked.isEmpty()) {
            emptyMap()
        } else {
            entryDao.summariesByIds(ranked.map { it.entryId }).associateBy { it.id }
        }
        val hits = ranked.mapNotNull { hit ->
            summaries[hit.entryId]?.let { row ->
                SearchHit(
                    summary = row.toSummary(),
                    score = hit.score,
                    snippet = hit.snippet,
                    matchedTerms = hit.matchedTerms,
                )
            }
        }
        val took = (System.nanoTime() - startedAt) / 1_000_000
        return SearchResults(query = query, hits = hits, tookMillis = took)
    }

    override fun observeRecentQueries(limit: Int): Flow<List<String>> =
        recentQueryDao.observeRecent(limit)

    override suspend fun recordQuery(query: String) {
        val trimmed = query.trim()
        if (trimmed.length < 2) return
        recentQueryDao.upsert(RecentQueryEntity(trimmed, System.currentTimeMillis()))
        recentQueryDao.trim(RECENT_QUERY_LIMIT)
    }

    override suspend fun clearRecentQueries() = recentQueryDao.clear()

    private companion object {
        const val RECENT_QUERY_LIMIT = 6
    }
}
