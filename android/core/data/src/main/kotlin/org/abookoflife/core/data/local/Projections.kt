package org.abookoflife.core.data.local

data class EntrySummaryRow(
    val id: String,
    val slug: String,
    val title: String,
    val domain: String,
    val tagsJson: String,
    val difficulty: String,
    val safety: String,
    val timeToComplete: String,
    val verificationStatus: String,
)

data class BookmarkRow(
    val entryId: String,
    val savedAt: Long,
    val slug: String,
    val title: String,
    val domain: String,
    val tagsJson: String,
    val difficulty: String,
    val safety: String,
    val timeToComplete: String,
    val verificationStatus: String,
)

data class EntryTextRow(
    val entryId: String,
    val title: String,
    val tags: String,
    val body: String,
)
