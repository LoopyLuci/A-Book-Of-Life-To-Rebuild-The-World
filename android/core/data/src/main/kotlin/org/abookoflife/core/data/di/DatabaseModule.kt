package org.abookoflife.core.data.di

import android.content.Context
import androidx.room.Room
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import org.abookoflife.core.data.local.AbookDatabase
import org.abookoflife.core.data.local.BookmarkDao
import org.abookoflife.core.data.local.DomainDao
import org.abookoflife.core.data.local.EntryDao
import org.abookoflife.core.data.local.EntryFtsDao
import org.abookoflife.core.data.local.MetaDao
import org.abookoflife.core.data.local.ReadingProgressDao
import org.abookoflife.core.data.local.RecentQueryDao
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object DatabaseModule {

    @Provides
    @Singleton
    fun provideDatabase(@ApplicationContext context: Context): AbookDatabase =
        Room.databaseBuilder(context, AbookDatabase::class.java, AbookDatabase.NAME)
            .fallbackToDestructiveMigration()
            .build()

    @Provides
    fun provideEntryDao(database: AbookDatabase): EntryDao = database.entryDao()

    @Provides
    fun provideEntryFtsDao(database: AbookDatabase): EntryFtsDao = database.entryFtsDao()

    @Provides
    fun provideBookmarkDao(database: AbookDatabase): BookmarkDao = database.bookmarkDao()

    @Provides
    fun provideReadingProgressDao(database: AbookDatabase): ReadingProgressDao =
        database.readingProgressDao()

    @Provides
    fun provideRecentQueryDao(database: AbookDatabase): RecentQueryDao = database.recentQueryDao()

    @Provides
    fun provideDomainDao(database: AbookDatabase): DomainDao = database.domainDao()

    @Provides
    fun provideMetaDao(database: AbookDatabase): MetaDao = database.metaDao()
}
