package org.abookoflife.core.data.search

import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import org.abookoflife.core.common.AppDispatchers
import org.abookoflife.core.data.decodeStringList
import org.abookoflife.core.data.local.EntryDao
import org.abookoflife.core.data.local.EntryFtsDao
import org.abookoflife.core.model.SearchFilters
import org.abookoflife.core.model.highlight
import java.util.Locale
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.math.min
import kotlin.math.sqrt

data class RankedHit(
    val entryId: String,
    val score: Double,
    val snippet: String,
    val matchedTerms: List<String>,
)

/**
 * Hybrid retrieval: SQLite FTS4 supplies a lexical candidate set which is
 * re-scored with BM25, a TF-IDF cosine pass adds a second ranking signal, and
 * Reciprocal Rank Fusion blends the two. Everything runs on-device.
 */
@Singleton
class SearchEngine @Inject constructor(
    private val entryDao: EntryDao,
    private val entryFtsDao: EntryFtsDao,
    private val dispatchers: AppDispatchers,
) {

    private val indexMutex = Mutex()

    @Volatile
    private var cachedIndex: SearchIndex? = null

    suspend fun ensureIndex(): SearchIndex {
        cachedIndex?.let { return it }
        return indexMutex.withLock {
            cachedIndex ?: buildIndex().also { cachedIndex = it }
        }
    }

    suspend fun buildIndex(): SearchIndex = withContext(dispatchers.io) {
        val rows = entryDao.allForIndex()
        val inputs = rows.map { entity ->
            DocInput(
                id = entity.id,
                title = entity.title,
                body = entity.body,
                tags = decodeStringList(entity.tagsJson),
                domain = entity.domain,
                difficulty = entity.difficulty,
                safety = entity.safety,
            )
        }
        SearchIndex.build(inputs)
    }

    suspend fun rebuild(): SearchIndex = indexMutex.withLock {
        buildIndex().also { cachedIndex = it }
    }

    fun invalidate() {
        cachedIndex = null
    }

    suspend fun search(query: String, filters: SearchFilters, limit: Int): List<RankedHit> {
        val trimmed = query.trim()
        if (trimmed.isEmpty()) return emptyList()

        val index = ensureIndex()
        if (index.documentCount == 0) return emptyList()

        val rawTerms = TextAnalyzer.rawTokens(trimmed)
        val analyzed = TextAnalyzer.analyze(trimmed)
        if (analyzed.isEmpty() && rawTerms.isEmpty()) return emptyList()

        val lexicalIds = lexicalCandidates(rawTerms)

        val expandedTerms = LinkedHashSet<String>()
        for (term in analyzed) {
            expandedTerms.add(term)
            val prefix = term.take(min(term.length, MAX_PREFIX_LENGTH))
            index.termsWithPrefix(prefix, PREFIX_EXPANSIONS)
                .filter { it != term }
                .forEach { expandedTerms.add(it) }
        }

        val queryVector = HashMap<String, Double>()
        for (term in expandedTerms) {
            val idf = index.idf(term)
            if (idf > 0.0) queryVector[term] = idf
        }
        if (queryVector.isEmpty()) return emptyList()

        val queryNorm = sqrt(queryVector.values.sumOf { it * it })

        val candidateIds = LinkedHashSet<String>(lexicalIds)
        for (term in queryVector.keys) candidateIds.addAll(index.posting(term).keys)
        if (candidateIds.isEmpty()) return emptyList()

        val bm25 = HashMap<String, Double>(candidateIds.size)
        val cosine = HashMap<String, Double>(candidateIds.size)
        val docLengthFactorBase = 1.0 - BM25_B

        for (id in candidateIds) {
            val doc = index.doc(id) ?: continue
            if (!passesFilters(doc, filters)) continue

            var bm25Score = 0.0
            var dot = 0.0
            for (term in queryVector.keys) {
                val tf = doc.frequency[term] ?: continue
                val idf = index.idf(term)
                val denominator = tf + BM25_K1 * (docLengthFactorBase + BM25_B * doc.length / index.averageLength)
                bm25Score += idf * (tf * (BM25_K1 + 1.0)) / denominator
                dot += queryVector.getValue(term) * (tf * idf)
            }
            bm25[id] = bm25Score
            cosine[id] = if (doc.norm > 0.0 && queryNorm > 0.0) dot / (doc.norm * queryNorm) else 0.0
        }

        if (bm25.isEmpty()) return emptyList()

        val bm25Ranks = rankMap(bm25)
        val cosineRanks = rankMap(cosine)
        val lexicalSet = lexicalIds.toHashSet()

        val fused = HashMap<String, Double>(bm25.size)
        for (id in bm25.keys) {
            var score = 0.0
            bm25Ranks[id]?.let { score += 1.0 / (RRF_K + it) }
            cosineRanks[id]?.let { score += 1.0 / (RRF_K + it) }
            if (id in lexicalSet) score += LEXICAL_BONUS
            fused[id] = score
        }

        return fused.entries
            .sortedByDescending { it.value }
            .take(limit)
            .map { (id, score) ->
                val doc = index.doc(id)
                RankedHit(
                    entryId = id,
                    score = score,
                    snippet = doc?.let { makeSnippet(it.body, rawTerms) }.orEmpty(),
                    matchedTerms = rawTerms.filter { term ->
                        val freq = doc?.frequency ?: return@filter false
                        freq.keys.any { it.startsWith(TextAnalyzer.stem(term)) }
                    },
                )
            }
    }

    private suspend fun lexicalCandidates(rawTerms: List<String>): List<String> =
        withContext(dispatchers.io) {
            val ftsQuery = rawTerms
                .filter { it.length >= 2 }
                .distinct()
                .take(MAX_FTS_TERMS)
                .joinToString(" OR ") { "$it*" }
            if (ftsQuery.isEmpty()) {
                emptyList()
            } else {
                runCatching { entryFtsDao.search(ftsQuery, CANDIDATE_LIMIT) }.getOrDefault(emptyList())
            }
        }

    private fun passesFilters(doc: SearchIndex.Doc, filters: SearchFilters): Boolean {
        if (filters.domains.isNotEmpty() && doc.domain !in filters.domains) return false
        if (filters.difficulties.isNotEmpty() &&
            filters.difficulties.none { it.id == doc.difficulty }
        ) return false
        if (filters.safety.isNotEmpty() && filters.safety.none { it.id == doc.safety }) return false
        return true
    }

    private fun rankMap(scores: Map<String, Double>): Map<String, Int> {
        val sorted = scores.entries.sortedByDescending { it.value }
        val ranks = HashMap<String, Int>(sorted.size)
        sorted.forEachIndexed { index, entry -> ranks[entry.key] = index + 1 }
        return ranks
    }

    private fun makeSnippet(body: String, rawTerms: List<String>): String {
        val plain = stripMarkdown(body)
        if (plain.isBlank()) return ""
        val lower = plain.lowercase(Locale.ROOT)

        var bestPos = -1
        for (term in rawTerms) {
            if (term.length < 2) continue
            val pos = lower.indexOf(term)
            if (pos >= 0 && (bestPos < 0 || pos < bestPos)) bestPos = pos
        }

        val start = if (bestPos < 0) 0 else maxOf(0, bestPos - SNIPPET_LEAD)
        val end = min(plain.length, start + SNIPPET_LENGTH)
        var slice = plain.substring(start, end).replace(WHITESPACE, " ").trim()

        for (term in rawTerms.distinct().sortedByDescending { it.length }) {
            if (term.length < 2) continue
            val regex = Regex("(?i)\\b" + Regex.escape(term) + "\\w*")
            slice = regex.replace(slice) { match -> highlight(match.value) }
        }

        val prefix = if (start > 0) "…" else ""
        val suffix = if (end < plain.length) "…" else ""
        return prefix + slice + suffix
    }

    private fun stripMarkdown(text: String): String = text
        .replace(Regex("```[\\s\\S]*?```"), " ")
        .replace(Regex("!?\\[([^\\]]*)]\\([^)]*\\)"), "$1")
        .replace(Regex("[#>*`_~]"), " ")
        .replace(Regex("^\\s*[-+*]\\s+", RegexOption.MULTILINE), " ")

    companion object {
        const val CANDIDATE_LIMIT = 200
        private const val MAX_FTS_TERMS = 12
        private const val PREFIX_EXPANSIONS = 6
        private const val MAX_PREFIX_LENGTH = 8
        private const val BM25_K1 = 1.2
        private const val BM25_B = 0.75
        private const val RRF_K = 60.0
        private const val LEXICAL_BONUS = 0.005
        private const val SNIPPET_LEAD = 80
        private const val SNIPPET_LENGTH = 220
        private val WHITESPACE = Regex("\\s+")
    }
}
