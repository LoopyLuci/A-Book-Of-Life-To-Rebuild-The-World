package org.abookoflife.core.common

import kotlin.math.max

object TextUtils {

    private val whitespace = Regex("\\s+")

    fun slugify(input: String): String = input
        .trim()
        .lowercase()
        .replace(Regex("[^a-z0-9\\s-]"), "")
        .replace(whitespace, "-")
        .trim('-')

    fun wordCount(text: String): Int =
        text.trim().split(whitespace).count { it.isNotBlank() }

    /** Rough reading-time estimate, capped to at least one minute. */
    fun estimateReadingMinutes(text: String, wordsPerMinute: Int = 200): Int =
        max(1, (wordCount(text) + wordsPerMinute - 1) / wordsPerMinute)

    fun ellipsize(text: String, maxChars: Int): String {
        val collapsed = text.replace(whitespace, " ").trim()
        return if (collapsed.length <= maxChars) collapsed
        else collapsed.take(maxChars).trimEnd() + "…"
    }
}
