package org.abookoflife.core.model

data class Source(
    val title: String,
    val author: String? = null,
    val url: String? = null,
    val license: String? = null,
    val year: Int? = null,
)

data class Verification(
    val status: VerificationStatus = VerificationStatus.DRAFT,
    val reviewers: List<String> = emptyList(),
    val testedBy: String? = null,
    val date: String? = null,
    val location: String? = null,
    val notes: String? = null,
)

/**
 * The full knowledge-base entry, including its Markdown body.
 */
data class Entry(
    val id: String,
    val slug: String,
    val title: String,
    val domain: String,
    val tags: List<String>,
    val difficulty: Difficulty,
    val safety: SafetyLevel,
    val timeToComplete: String?,
    val expectedYield: String?,
    val season: String?,
    val storage: String?,
    val cost: CostTier,
    val hazards: List<String>,
    val prerequisites: List<String>,
    val materialsRequired: List<String>,
    val toolsRequired: List<String>,
    val sources: List<Source>,
    val verification: Verification,
    val links: List<String>,
    val regions: List<String>,
    val language: String,
    val body: String,
) {
    val verificationStatus: VerificationStatus get() = verification.status
}

/**
 * Lightweight projection used by lists, search results and bookmarks.
 */
data class EntrySummary(
    val id: String,
    val slug: String,
    val title: String,
    val domain: String,
    val difficulty: Difficulty,
    val safety: SafetyLevel,
    val verificationStatus: VerificationStatus,
    val tags: List<String>,
    val timeToComplete: String?,
)
