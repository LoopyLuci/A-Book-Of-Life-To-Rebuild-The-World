package org.abookoflife.core.data.local

import androidx.room.Database
import androidx.room.RoomDatabase

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
    version = 1,
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
    }
}
