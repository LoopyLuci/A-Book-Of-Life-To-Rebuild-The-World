package org.abookoflife.core.data

import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import org.abookoflife.core.data.content.SourceDto
import org.abookoflife.core.data.local.BookmarkRow
import org.abookoflife.core.data.local.DomainEntity
import org.abookoflife.core.data.local.EntryEntity
import org.abookoflife.core.data.local.EntrySummaryRow
import org.abookoflife.core.model.Bookmark
import org.abookoflife.core.model.CostTier
import org.abookoflife.core.model.Difficulty
import org.abookoflife.core.model.Domain
import org.abookoflife.core.model.Entry
import org.abookoflife.core.model.EntrySummary
import org.abookoflife.core.model.SafetyLevel
import org.abookoflife.core.model.Source
import org.abookoflife.core.model.Verification
import org.abookoflife.core.model.VerificationStatus

fun encodeStringList(values: List<String>): String = JsonCodec.json.encodeToString(values)

fun decodeStringList(json: String): List<String> =
    if (json.isBlank()) emptyList()
    else runCatching { JsonCodec.json.decodeFromString<List<String>>(json) }.getOrDefault(emptyList())

fun encodeSources(values: List<SourceDto>): String = JsonCodec.json.encodeToString(values)

fun decodeSources(json: String): List<SourceDto> =
    if (json.isBlank()) emptyList()
    else runCatching { JsonCodec.json.decodeFromString<List<SourceDto>>(json) }.getOrDefault(emptyList())

fun EntryEntity.toEntry(): Entry = Entry(
    id = id,
    slug = slug,
    title = title,
    domain = domain,
    tags = decodeStringList(tagsJson),
    difficulty = Difficulty.fromId(difficulty),
    safety = SafetyLevel.fromId(safety),
    timeToComplete = timeToComplete.ifBlank { null },
    expectedYield = expectedYield.ifBlank { null },
    season = season.ifBlank { null },
    storage = storage.ifBlank { null },
    cost = CostTier.fromId(costTier),
    hazards = decodeStringList(hazardsJson),
    prerequisites = decodeStringList(prerequisitesJson),
    materialsRequired = decodeStringList(materialsJson),
    toolsRequired = decodeStringList(toolsJson),
    sources = decodeSources(sourcesJson).map {
        Source(
            title = it.title,
            author = it.author.ifBlank { null },
            url = it.url.ifBlank { null },
            license = it.license.ifBlank { null },
            year = it.year.takeIf { year -> year > 0 },
        )
    },
    verification = Verification(
        status = VerificationStatus.fromId(verificationStatus),
        reviewers = decodeStringList(verificationReviewersJson),
        testedBy = verificationTestedBy.ifBlank { null },
        date = verificationDate.ifBlank { null },
        location = verificationLocation.ifBlank { null },
        notes = verificationNotes.ifBlank { null },
    ),
    links = decodeStringList(linksJson),
    regions = decodeStringList(regionsJson),
    language = language,
    body = body,
)

fun EntrySummaryRow.toSummary(): EntrySummary = EntrySummary(
    id = id,
    slug = slug,
    title = title,
    domain = domain,
    difficulty = Difficulty.fromId(difficulty),
    safety = SafetyLevel.fromId(safety),
    verificationStatus = VerificationStatus.fromId(verificationStatus),
    tags = decodeStringList(tagsJson),
    timeToComplete = timeToComplete.ifBlank { null },
)

fun BookmarkRow.toBookmark(): Bookmark = Bookmark(
    entry = EntrySummary(
        id = entryId,
        slug = slug,
        title = title,
        domain = domain,
        difficulty = Difficulty.fromId(difficulty),
        safety = SafetyLevel.fromId(safety),
        verificationStatus = VerificationStatus.fromId(verificationStatus),
        tags = decodeStringList(tagsJson),
        timeToComplete = timeToComplete.ifBlank { null },
    ),
    savedAt = savedAt,
)

fun DomainEntity.toDomain(): Domain = Domain(
    slug = slug,
    title = title,
    description = description,
    icon = icon,
    colorHex = colorHex,
    entryCount = entryCount,
)
