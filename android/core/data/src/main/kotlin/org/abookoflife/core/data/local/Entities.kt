package org.abookoflife.core.data.local

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.Fts4
import androidx.room.FtsOptions
import androidx.room.PrimaryKey

@Entity(tableName = "entries")
data class EntryEntity(
    @PrimaryKey val id: String,
    val slug: String,
    val title: String,
    val domain: String,
    val tagsJson: String,
    val difficulty: String,
    val safety: String,
    val timeToComplete: String,
    @ColumnInfo(defaultValue = "") val expectedYield: String,
    @ColumnInfo(defaultValue = "") val season: String,
    @ColumnInfo(defaultValue = "") val storage: String,
    @ColumnInfo(defaultValue = "unknown") val costTier: String,
    @ColumnInfo(defaultValue = "[]") val hazardsJson: String,
    val prerequisitesJson: String,
    val materialsJson: String,
    val toolsJson: String,
    val linksJson: String,
    val regionsJson: String,
    val sourcesJson: String,
    val language: String,
    val verificationStatus: String,
    val verificationReviewersJson: String,
    val verificationTestedBy: String,
    val verificationDate: String,
    val verificationLocation: String,
    val verificationNotes: String,
    val body: String,
    val bodyLength: Int,
)

@Fts4(tokenizer = FtsOptions.TOKENIZER_PORTER)
@Entity(tableName = "entries_fts")
data class EntryFtsEntity(
    @PrimaryKey @ColumnInfo(name = "rowid") val rowId: Int,
    val entryId: String,
    val title: String,
    val tags: String,
    val body: String,
)

@Entity(tableName = "bookmarks")
data class BookmarkEntity(
    @PrimaryKey val entryId: String,
    val savedAt: Long,
)

@Entity(tableName = "reading_progress")
data class ReadingProgressEntity(
    @PrimaryKey val entryId: String,
    val lastOpenedAt: Long,
    val scrollFraction: Float,
)

@Entity(tableName = "recent_queries")
data class RecentQueryEntity(
    @PrimaryKey val query: String,
    val lastUsedAt: Long,
)

@Entity(tableName = "domains")
data class DomainEntity(
    @PrimaryKey val slug: String,
    val title: String,
    val description: String,
    val icon: String,
    val colorHex: String,
    val entryCount: Int,
    val sortOrder: Int,
)

@Entity(tableName = "kb_meta")
data class MetaEntity(
    @PrimaryKey val key: String,
    val value: String,
)
