package org.abookoflife.core.data.search

import java.util.Locale

/**
 * Lightweight language-normalisation pipeline: lower-casing, tokenisation,
 * stop-word removal and a conservative suffix stemmer. Keeps the offline index
 * small and deterministic without pulling in a full NLP stack.
 */
object TextAnalyzer {

    private val wordRegex = Regex("[a-z0-9]+")

    val stopWords: Set<String> = setOf(
        "the", "a", "an", "and", "or", "of", "to", "in", "for", "on", "with", "is", "are", "be",
        "as", "by", "at", "it", "this", "that", "from", "into", "your", "you", "can", "will",
        "not", "but", "if", "then", "than", "so", "such", "use", "using", "used", "when", "which",
        "while", "their", "them", "they", "we", "our", "its", "also", "may", "more", "most", "some",
        "any", "all", "each", "how", "what", "who", "why", "where", "there", "here", "these",
        "those", "over", "under", "about", "after", "before", "between", "during", "through", "up",
        "down", "out", "off", "no", "yes", "do", "does", "did", "done", "has", "have", "had", "was",
        "were", "been", "being", "one", "two", "three", "first", "second", "new", "old", "like",
        "just", "only", "very", "well", "even", "still", "get", "got", "make", "made", "take",
        "taken", "give", "given", "onto", "upon", "must", "should", "would", "could", "need",
    )

    fun rawTokens(text: String): List<String> =
        wordRegex.findAll(text.lowercase(Locale.ROOT)).map { it.value }.toList()

    fun analyze(text: String): List<String> =
        rawTokens(text)
            .filter { it.length >= 2 && it !in stopWords }
            .map(::stem)

    /** Conservative suffix stripper; avoids over-stemming short words. */
    fun stem(word: String): String {
        var s = word
        if (s.length > 4) {
            s = when {
                s.endsWith("ies") -> s.dropLast(3) + "y"
                s.endsWith("sses") -> s.dropLast(2)
                s.endsWith("ses") -> s.dropLast(2)
                s.endsWith("ches") || s.endsWith("shes") -> s.dropLast(2)
                s.endsWith("s") && !s.endsWith("ss") && !s.endsWith("us") -> s.dropLast(1)
                else -> s
            }
        }
        if (s.length > 5 && s.endsWith("ing")) s = s.dropLast(3)
        if (s.length > 4 && s.endsWith("ed")) s = s.dropLast(2)
        if (s.length > 5 && s.endsWith("ly")) s = s.dropLast(2)
        return s
    }
}
