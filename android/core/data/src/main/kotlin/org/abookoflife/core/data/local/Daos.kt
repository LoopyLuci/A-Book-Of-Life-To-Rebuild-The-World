package org.abookoflife.core.data.local

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

private const val SUMMARY_COLUMNS =
    "id, slug, title, domain, tagsJson, difficulty, safety, timeToComplete, verificationStatus"

@Dao
interface EntryDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(entries: List<EntryEntity>)

    @Query("DELETE FROM entries")
    suspend fun deleteAll()

    @Query("SELECT COUNT(*) FROM entries")
    suspend fun count(): Int

    @Query("SELECT COUNT(*) FROM entries")
    fun observeCount(): Flow<Int>

    @Query("SELECT COUNT(*) FROM entries WHERE verificationStatus IN ('field_tested','peer_reviewed')")
    fun observeVerifiedCount(): Flow<Int>

    @Query("SELECT $SUMMARY_COLUMNS FROM entries ORDER BY title ASC")
    fun observeAllSummaries(): Flow<List<EntrySummaryRow>>

    @Query("SELECT $SUMMARY_COLUMNS FROM entries WHERE domain = :domain ORDER BY title ASC")
    fun observeSummariesByDomain(domain: String): Flow<List<EntrySummaryRow>>

    @Query("SELECT $SUMMARY_COLUMNS FROM entries WHERE verificationStatus = 'field_tested' ORDER BY title ASC LIMIT :limit")
    suspend fun fieldTested(limit: Int): List<EntrySummaryRow>

    @Query("SELECT $SUMMARY_COLUMNS FROM entries WHERE id IN (:ids)")
    suspend fun summariesByIds(ids: List<String>): List<EntrySummaryRow>

    @Query("SELECT $SUMMARY_COLUMNS FROM entries WHERE id IN (:ids)")
    fun observeSummariesByIds(ids: List<String>): Flow<List<EntrySummaryRow>>

    @Query("SELECT * FROM entries WHERE id = :id LIMIT 1")
    suspend fun entry(id: String): EntryEntity?

    @Query("SELECT id FROM entries WHERE slug = :slug LIMIT 1")
    suspend fun idBySlug(slug: String): String?

    @Query("SELECT * FROM entries WHERE id = :id LIMIT 1")
    fun observeEntry(id: String): Flow<EntryEntity?>

    @Query("SELECT * FROM entries")
    suspend fun allForIndex(): List<EntryEntity>
}

@Dao
interface EntryFtsDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(rows: List<EntryFtsEntity>)

    @Query("DELETE FROM entries_fts")
    suspend fun deleteAll()

    @Query("SELECT entryId FROM entries_fts WHERE entries_fts MATCH :query LIMIT :limit")
    suspend fun search(query: String, limit: Int): List<String>

    @Query("SELECT entryId, title, tags, body FROM entries_fts")
    suspend fun all(): List<EntryTextRow>
}

@Dao
interface BookmarkDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(bookmark: BookmarkEntity)

    @Query("DELETE FROM bookmarks WHERE entryId = :entryId")
    suspend fun delete(entryId: String)

    @Query(
        """
        SELECT b.entryId AS entryId, b.savedAt AS savedAt, e.slug AS slug, e.title AS title,
               e.domain AS domain, e.tagsJson AS tagsJson, e.difficulty AS difficulty,
               e.safety AS safety, e.timeToComplete AS timeToComplete,
               e.verificationStatus AS verificationStatus
        FROM bookmarks b INNER JOIN entries e ON e.id = b.entryId
        ORDER BY b.savedAt DESC
        """
    )
    fun observeAll(): Flow<List<BookmarkRow>>

    @Query("SELECT EXISTS(SELECT 1 FROM bookmarks WHERE entryId = :entryId)")
    fun observeIsBookmarked(entryId: String): Flow<Boolean>

    @Query("SELECT EXISTS(SELECT 1 FROM bookmarks WHERE entryId = :entryId)")
    suspend fun isBookmarked(entryId: String): Boolean

    @Query("SELECT entryId FROM bookmarks")
    suspend fun allIds(): List<String>
}

@Dao
interface ReadingProgressDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(progress: ReadingProgressEntity)

    @Query("SELECT * FROM reading_progress ORDER BY lastOpenedAt DESC LIMIT 1")
    fun observeMostRecent(): Flow<ReadingProgressEntity?>

    @Query("SELECT * FROM reading_progress WHERE entryId = :entryId LIMIT 1")
    fun observeFor(entryId: String): Flow<ReadingProgressEntity?>

    @Query("DELETE FROM reading_progress WHERE entryId = :entryId")
    suspend fun delete(entryId: String)
}

@Dao
interface RecentQueryDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(query: RecentQueryEntity)

    @Query("SELECT query FROM recent_queries ORDER BY lastUsedAt DESC LIMIT :limit")
    fun observeRecent(limit: Int): Flow<List<String>>

    @Query("DELETE FROM recent_queries")
    suspend fun clear()

    @Query("DELETE FROM recent_queries WHERE query NOT IN (SELECT query FROM recent_queries ORDER BY lastUsedAt DESC LIMIT :keep)")
    suspend fun trim(keep: Int)
}

@Dao
interface DomainDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertAll(domains: List<DomainEntity>)

    @Query("DELETE FROM domains")
    suspend fun deleteAll()

    @Query("SELECT * FROM domains ORDER BY sortOrder ASC")
    fun observeAll(): Flow<List<DomainEntity>>

    @Query("SELECT * FROM domains WHERE slug = :slug LIMIT 1")
    suspend fun bySlug(slug: String): DomainEntity?

    @Query("SELECT * FROM domains WHERE slug = :slug LIMIT 1")
    fun observeBySlug(slug: String): Flow<DomainEntity?>

    @Query("SELECT COUNT(*) FROM domains")
    fun observeCount(): Flow<Int>
}

@Dao
interface MetaDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun put(meta: MetaEntity)

    @Query("SELECT value FROM kb_meta WHERE `key` = :key LIMIT 1")
    suspend fun get(key: String): String?

    @Query("SELECT value FROM kb_meta WHERE `key` = :key LIMIT 1")
    fun observe(key: String): Flow<String?>
}
