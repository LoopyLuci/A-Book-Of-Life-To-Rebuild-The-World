package org.abookoflife.core.data.content

import android.content.Context
import androidx.room.withTransaction
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.withContext
import kotlinx.serialization.decodeFromString
import org.abookoflife.core.common.AppDispatchers
import org.abookoflife.core.data.JsonCodec
import org.abookoflife.core.data.encodeSources
import org.abookoflife.core.data.encodeStringList
import org.abookoflife.core.data.local.AbookDatabase
import org.abookoflife.core.data.local.DomainEntity
import org.abookoflife.core.data.local.EntryEntity
import org.abookoflife.core.data.local.EntryFtsEntity
import org.abookoflife.core.data.local.MetaEntity
import org.abookoflife.core.data.search.SearchEngine
import org.abookoflife.core.model.CostTier
import org.abookoflife.core.model.Difficulty
import org.abookoflife.core.model.SafetyLevel
import org.abookoflife.core.model.VerificationStatus
import javax.inject.Inject
import javax.inject.Singleton

data class ImportResult(
    val imported: Boolean,
    val entryCount: Int,
    val kbVersion: String,
)

@Singleton
class ContentImporter @Inject constructor(
    @ApplicationContext private val context: Context,
    private val database: AbookDatabase,
    private val searchEngine: SearchEngine,
    private val dispatchers: AppDispatchers,
) {

    suspend fun importIfNeeded(force: Boolean = false): ImportResult = withContext(dispatchers.io) {
        val meta = readMeta()
        val storedVersion = database.metaDao().get(AbookDatabase.META_KB_VERSION)
        val storedCount = database.entryDao().count()
        val storedHash = database.metaDao().get(AbookDatabase.META_CONTENT_HASH)

        // Re-import when the KB version, entry count or content fingerprint changes,
        // so refreshes are picked up even when the version is not bumped.
        val hashMatches = meta.contentHash.isEmpty() || storedHash == meta.contentHash
        val alreadyCurrent = !force &&
            storedVersion == meta.kbVersion &&
            storedCount == meta.entryCount &&
            hashMatches &&
            storedCount > 0

        if (alreadyCurrent) {
            return@withContext ImportResult(false, storedCount, storedVersion ?: meta.kbVersion)
        }

        val entries = readEntries()
        val domains = readDomains(entries)

        database.withTransaction {
            database.entryFtsDao().deleteAll()
            database.entryDao().deleteAll()
            database.domainDao().deleteAll()

            database.entryDao().insertAll(entries.map { it.toEntity() })
            database.entryFtsDao().insertAll(
                entries.mapIndexed { index, dto ->
                    EntryFtsEntity(
                        rowId = index,
                        entryId = dto.id,
                        title = dto.title,
                        tags = dto.tags.joinToString(" "),
                        body = dto.body,
                    )
                }
            )
            database.domainDao().insertAll(domains)

            database.metaDao().put(MetaEntity(AbookDatabase.META_KB_VERSION, meta.kbVersion))
            database.metaDao().put(MetaEntity(AbookDatabase.META_ENTRY_COUNT, entries.size.toString()))
            database.metaDao().put(MetaEntity(AbookDatabase.META_CONTENT_HASH, meta.contentHash))
            database.metaDao().put(
                MetaEntity(AbookDatabase.META_IMPORTED_AT, System.currentTimeMillis().toString())
            )
        }

        searchEngine.rebuild()

        ImportResult(imported = true, entryCount = entries.size, kbVersion = meta.kbVersion)
    }

    suspend fun reindex(): ImportResult = importIfNeeded(force = true)

    private fun readMeta(): MetaDto = readAsset("content/meta.json")
        .let { JsonCodec.json.decodeFromString<MetaDto>(it) }

    private fun readEntries(): List<EntryDto> = readAsset("content/entries.json")
        .let { JsonCodec.json.decodeFromString<List<EntryDto>>(it) }

    private fun readDomains(entries: List<EntryDto>): List<DomainEntity> {
        val dto = readAsset("content/domains.json")
            .let { JsonCodec.json.decodeFromString<List<DomainDto>>(it) }
        val counts = entries.groupingBy { it.domain }.eachCount()
        return dto.mapIndexed { index, domain ->
            DomainEntity(
                slug = domain.slug,
                title = domain.title,
                description = domain.description,
                icon = domain.icon,
                colorHex = domain.color,
                entryCount = counts[domain.slug] ?: domain.entryCount,
                sortOrder = index,
            )
        }
    }

    private fun readAsset(path: String): String =
        context.assets.open(path).bufferedReader(Charsets.UTF_8).use { it.readText() }

    private fun EntryDto.toEntity(): EntryEntity = EntryEntity(
        id = id,
        slug = slug,
        title = title,
        domain = domain,
        tagsJson = encodeStringList(tags),
        difficulty = Difficulty.fromId(difficulty).id,
        safety = SafetyLevel.fromId(safety).id,
        timeToComplete = timeToComplete,
        expectedYield = yield,
        season = season,
        storage = storage,
        costTier = CostTier.fromId(cost).id,
        hazardsJson = encodeStringList(hazards),
        prerequisitesJson = encodeStringList(prerequisites),
        materialsJson = encodeStringList(materialsRequired),
        toolsJson = encodeStringList(toolsRequired),
        linksJson = encodeStringList(links),
        regionsJson = encodeStringList(regions),
        sourcesJson = encodeSources(sources),
        language = language,
        verificationStatus = VerificationStatus.fromId(verification.status).id,
        verificationReviewersJson = encodeStringList(verification.reviewers),
        verificationTestedBy = verification.testedBy,
        verificationDate = verification.date,
        verificationLocation = verification.location,
        verificationNotes = verification.notes,
        body = body,
        bodyLength = body.length,
    )
}
