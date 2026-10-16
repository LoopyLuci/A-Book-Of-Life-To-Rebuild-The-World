package org.abookoflife.core.data.search

import kotlin.math.ln
import kotlin.math.sqrt

data class DocInput(
    val id: String,
    val title: String,
    val body: String,
    val tags: List<String>,
    val domain: String,
    val difficulty: String,
    val safety: String,
)

/**
 * Immutable in-memory inverted index. The knowledge base is small enough that the
 * whole corpus can live in RAM, which keeps ranking fast and fully offline.
 */
class SearchIndex private constructor(
    private val docs: Map<String, Doc>,
    private val postings: Map<String, Map<String, Int>>,
    private val sortedTerms: List<String>,
) {

    class Doc(
        val id: String,
        val title: String,
        val body: String,
        val tags: List<String>,
        val domain: String,
        val difficulty: String,
        val safety: String,
        val frequency: Map<String, Int>,
        val length: Int,
        val norm: Double,
    )

    val documentCount: Int = docs.size

    val averageLength: Double =
        if (docs.isEmpty()) 1.0 else docs.values.sumOf { it.length }.toDouble() / docs.size

    fun doc(id: String): Doc? = docs[id]

    fun allDocs(): Collection<Doc> = docs.values

    fun documentFrequency(term: String): Int = postings[term]?.size ?: 0

    fun idf(term: String): Double {
        val df = documentFrequency(term)
        if (df == 0) return 0.0
        return ln(1.0 + (documentCount - df + 0.5) / (df + 0.5))
    }

    fun posting(term: String): Map<String, Int> = postings[term].orEmpty()

    fun termsWithPrefix(prefix: String, limit: Int): List<String> {
        if (prefix.isEmpty() || sortedTerms.isEmpty()) return emptyList()
        var low = 0
        var high = sortedTerms.size
        while (low < high) {
            val mid = (low + high) / 2
            if (sortedTerms[mid] < prefix) low = mid + 1 else high = mid
        }
        val result = ArrayList<String>(limit)
        var i = low
        while (i < sortedTerms.size && result.size < limit && sortedTerms[i].startsWith(prefix)) {
            result.add(sortedTerms[i])
            i++
        }
        return result
    }

    companion object {
        fun build(inputs: List<DocInput>): SearchIndex {
            val frequencies = HashMap<String, MutableMap<String, Int>>(inputs.size)
            val lengths = HashMap<String, Int>(inputs.size)

            for (input in inputs) {
                val freq = HashMap<String, Int>()
                fun accumulate(text: String, weight: Int) {
                    for (term in TextAnalyzer.analyze(text)) {
                        freq[term] = (freq[term] ?: 0) + weight
                    }
                }
                accumulate(input.title, TITLE_WEIGHT)
                input.tags.forEach { accumulate(it, TAG_WEIGHT) }
                accumulate(input.body, BODY_WEIGHT)
                frequencies[input.id] = freq
                lengths[input.id] = freq.values.sum()
            }

            val postings = HashMap<String, MutableMap<String, Int>>()
            for ((id, freq) in frequencies) {
                for ((term, tf) in freq) {
                    postings.getOrPut(term) { HashMap() }[id] = tf
                }
            }

            val total = inputs.size
            val idfCache = HashMap<String, Double>()
            fun idfOf(term: String): Double = idfCache.getOrPut(term) {
                val df = postings[term]?.size ?: 0
                if (df == 0) 0.0 else ln(1.0 + (total - df + 0.5) / (df + 0.5))
            }

            val docs = HashMap<String, Doc>(inputs.size)
            for (input in inputs) {
                val freq = frequencies.getValue(input.id)
                var sumSquares = 0.0
                for ((term, tf) in freq) {
                    val weight = tf * idfOf(term)
                    sumSquares += weight * weight
                }
                docs[input.id] = Doc(
                    id = input.id,
                    title = input.title,
                    body = input.body,
                    tags = input.tags,
                    domain = input.domain,
                    difficulty = input.difficulty,
                    safety = input.safety,
                    frequency = freq,
                    length = lengths.getValue(input.id),
                    norm = sqrt(sumSquares),
                )
            }

            return SearchIndex(
                docs = docs,
                postings = postings.mapValues { it.value.toMap() },
                sortedTerms = postings.keys.sorted(),
            )
        }

        private const val TITLE_WEIGHT = 3
        private const val TAG_WEIGHT = 2
        private const val BODY_WEIGHT = 1
    }
}
