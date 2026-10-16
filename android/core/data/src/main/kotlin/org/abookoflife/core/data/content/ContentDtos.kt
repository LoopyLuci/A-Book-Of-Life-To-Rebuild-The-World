package org.abookoflife.core.data.content

import kotlinx.serialization.Serializable

@Serializable
data class EntryDto(
    val id: String,
    val slug: String,
    val title: String,
    val domain: String,
    val tags: List<String> = emptyList(),
    val difficulty: String = "unknown",
    val safety: String = "unknown",
    val timeToComplete: String = "",
    val prerequisites: List<String> = emptyList(),
    val materialsRequired: List<String> = emptyList(),
    val toolsRequired: List<String> = emptyList(),
    val sources: List<SourceDto> = emptyList(),
    val verification: VerificationDto = VerificationDto(),
    val links: List<String> = emptyList(),
    val regions: List<String> = emptyList(),
    val language: String = "en",
    val body: String = "",
)

@Serializable
data class SourceDto(
    val title: String = "",
    val author: String = "",
    val url: String = "",
    val license: String = "",
    val year: Int = 0,
)

@Serializable
data class VerificationDto(
    val status: String = "draft",
    val reviewers: List<String> = emptyList(),
    val testedBy: String = "",
    val date: String = "",
    val location: String = "",
    val notes: String = "",
)

@Serializable
data class DomainDto(
    val slug: String,
    val title: String,
    val description: String = "",
    val icon: String = "public",
    val color: String = "#2E6B3E",
    val entryCount: Int = 0,
)

@Serializable
data class MetaDto(
    val kbVersion: String = "0.0.0",
    val contentHash: String = "",
    val entryCount: Int = 0,
    val domainCount: Int = 0,
    val defaultLanguage: String = "en",
    val license: String = "CC-BY-SA-4.0",
)
