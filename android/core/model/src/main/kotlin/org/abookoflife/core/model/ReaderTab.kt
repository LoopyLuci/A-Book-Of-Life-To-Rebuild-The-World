package org.abookoflife.core.model

/**
 * A page kept open in the reader's tab strip.
 */
data class ReaderTab(
    val entryId: String,
    val title: String,
    val domain: String = "",
)
