package org.abookoflife.core.common

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class TextUtilsTest {

    @Test
    fun slugify_lowercases_and_hyphenates() {
        assertThat(TextUtils.slugify("Water Purification")).isEqualTo("water-purification")
    }

    @Test
    fun slugify_trims_and_strips_punctuation() {
        assertThat(TextUtils.slugify("  First  Aid!  ")).isEqualTo("first-aid")
    }

    @Test
    fun wordCount_ignores_extra_whitespace() {
        assertThat(TextUtils.wordCount("one   two\n\tthree")).isEqualTo(3)
    }

    @Test
    fun estimateReadingMinutes_is_at_least_one() {
        assertThat(TextUtils.estimateReadingMinutes("")).isEqualTo(1)
        assertThat(TextUtils.estimateReadingMinutes("word ".repeat(200))).isEqualTo(1)
        assertThat(TextUtils.estimateReadingMinutes("word ".repeat(201))).isEqualTo(2)
    }

    @Test
    fun ellipsize_truncates_long_text() {
        assertThat(TextUtils.ellipsize("hi", 5)).isEqualTo("hi")
        assertThat(TextUtils.ellipsize("hello world", 5)).isEqualTo("hello…")
    }
}
