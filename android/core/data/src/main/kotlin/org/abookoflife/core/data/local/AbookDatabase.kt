package org.abookoflife.core.data.local

import androidx.room.Database
import androidx.room.RoomDatabase
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

@Database(
    entities = [
        EntryEntity::class,
        EntryFtsEntity::class,
        BookmarkEntity::class,
        ReadingProgressEntity::class,
        RecentQueryEntity::class,
        DomainEntity::class,
        MetaEntity::class,
    ],
    version = 2,
    exportSchema = false,
)
abstract class AbookDatabase : RoomDatabase() {
    abstract fun entryDao(): EntryDao
    abstract fun entryFtsDao(): EntryFtsDao
    abstract fun bookmarkDao(): BookmarkDao
    abstract fun readingProgressDao(): ReadingProgressDao
    abstract fun recentQueryDao(): RecentQueryDao
    abstract fun domainDao(): DomainDao
    abstract fun metaDao(): MetaDao

    companion object {
        const val NAME = "abook.db"
        const val META_KB_VERSION = "kb_version"
        const val META_IMPORTED_AT = "imported_at"
        const val META_ENTRY_COUNT = "entry_count"
        const val META_CONTENT_HASH = "content_hash"

        val MIGRATION_1_2 = object : Migration(1, 2) {
            override fun migrate(db: SupportSQLiteDatabase) {
                db.execSQL("ALTER TABLE entries ADD COLUMN expectedYield TEXT NOT NULL DEFAULT ''")
                db.execSQL("ALTER TABLE entries ADD COLUMN season TEXT NOT NULL DEFAULT ''")
                db.execSQL("ALTER TABLE entries ADD COLUMN storage TEXT NOT NULL DEFAULT ''")
                db.execSQL("ALTER TABLE entries ADD COLUMN costTier TEXT NOT NULL DEFAULT 'unknown'")
                db.execSQL("ALTER TABLE entries ADD COLUMN hazardsJson TEXT NOT NULL DEFAULT '[]'")
            }
        }
    }
}
