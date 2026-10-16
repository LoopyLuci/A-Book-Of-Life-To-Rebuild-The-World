package org.abookoflife.core.model

/** Guillemet markers wrapped around matched terms inside search snippets. */
const val HIGHLIGHT_OPEN = "\u00AB"
const val HIGHLIGHT_CLOSE = "\u00BB"

fun highlight(term: String): String = "$HIGHLIGHT_OPEN$term$HIGHLIGHT_CLOSE"

data class SearchFilters(
    val domains: Set<String> = emptySet(),
    val difficulties: Set<Difficulty> = emptySet(),
    val safety: Set<SafetyLevel> = emptySet(),
) {
    val isEmpty: Boolean
        get() = domains.isEmpty() && difficulties.isEmpty() && safety.isEmpty()

    fun toggleDomain(slug: String): SearchFilters =
        copy(domains = domains.toggle(slug))

    fun toggleDifficulty(value: Difficulty): SearchFilters =
        copy(difficulties = difficulties.toggle(value))

    fun toggleSafety(value: SafetyLevel): SearchFilters =
        copy(safety = safety.toggle(value))

    private fun <T> Set<T>.toggle(value: T): Set<T> =
        if (contains(value)) this - value else this + value
}

data class SearchHit(
    val summary: EntrySummary,
    val score: Double,
    val snippet: String,
    val matchedTerms: List<String>,
)

data class SearchResults(
    val query: String,
    val hits: List<SearchHit>,
    val tookMillis: Long,
)

data class Bookmark(
    val entry: EntrySummary,
    val savedAt: Long,
)
