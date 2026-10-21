package org.abookoflife.core.data.di

import dagger.Binds
import dagger.Module
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import org.abookoflife.core.data.preferences.DefaultReaderTabsRepository
import org.abookoflife.core.data.preferences.DefaultUserSettingsRepository
import org.abookoflife.core.data.preferences.ReaderTabsRepository
import org.abookoflife.core.data.preferences.UserSettingsRepository
import org.abookoflife.core.data.repository.DefaultKnowledgeRepository
import org.abookoflife.core.data.repository.KnowledgeRepository
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
abstract class RepositoryModule {

    @Binds
    @Singleton
    abstract fun bindKnowledgeRepository(impl: DefaultKnowledgeRepository): KnowledgeRepository

    @Binds
    @Singleton
    abstract fun bindUserSettingsRepository(
        impl: DefaultUserSettingsRepository,
    ): UserSettingsRepository

    @Binds
    @Singleton
    abstract fun bindReaderTabsRepository(
        impl: DefaultReaderTabsRepository,
    ): ReaderTabsRepository
}
