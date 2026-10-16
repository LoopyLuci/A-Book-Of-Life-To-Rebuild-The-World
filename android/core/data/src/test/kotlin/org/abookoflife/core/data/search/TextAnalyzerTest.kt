package org.abookoflife.core.data.search

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class TextAnalyzerTest {

    @Test
    fun rawTokens_lowercases_and_splits_on_non_alphanumerics() {
        assertThat(TextAnalyzer.rawTokens("Hello, WORLD! 42")).containsExactly("hello", "world", "42").inOrder()
    }

    @Test
    fun analyze_removes_stop_words_and_short_tokens() {
        assertThat(TextAnalyzer.analyze("the and of")).isEmpty()
        assertThat(TextAnalyzer.analyze("a b c")).isEmpty()
    }

    @Test
    fun analyze_stems_content_words() {
        assertThat(TextAnalyzer.analyze("Use water to purify water"))
            .containsExactly("water", "purify", "water")
            .inOrder()
    }

    @Test
    fun stem_strips_common_suffixes() {
        assertThat(TextAnalyzer.stem("shelters")).isEqualTo("shelter")
        assertThat(TextAnalyzer.stem("sheltering")).isEqualTo("shelter")
        assertThat(TextAnalyzer.stem("boiling")).isEqualTo("boil")
        assertThat(TextAnalyzer.stem("carry")).isEqualTo("carry")
    }
}
