package org.abookoflife.app

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onAllNodesWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToNode
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.google.common.truth.Truth.assertThat
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * End-to-end smoke tests that launch the real app: content import, home, ranked
 * search and the Markdown reader. Runtime is dominated by the first-launch import.
 */
@RunWith(AndroidJUnit4::class)
class AppSmokeTest {

    @get:Rule
    val rule = createAndroidComposeRule<MainActivity>()

    private fun awaitText(text: String, timeoutMillis: Long = 60_000) {
        rule.waitUntil(timeoutMillis) {
            rule.onAllNodesWithText(text, substring = true).fetchSemanticsNodes().isNotEmpty()
        }
    }

    private fun hasText(text: String): Boolean =
        rule.onAllNodesWithText(text, substring = true).fetchSemanticsNodes().isNotEmpty()

    @Test
    fun home_shows_library_and_navigation() {
        awaitText("A Book Of Life To Rebuild The World")

        rule.onNodeWithText("Library").assertIsDisplayed()
        rule.onNodeWithText("Search").assertIsDisplayed()
        rule.onNodeWithText("Saved").assertIsDisplayed()
        rule.onNodeWithText("Settings").assertIsDisplayed()

        // The domains section sits below the fold, so it only reaches the
        // screen once the home list is scrolled to it. Asserting it was
        // displayed without scrolling failed on every emulator.
        rule.onNodeWithTag("home_list").performScrollToNode(hasText("Domains", substring = true))
        rule.onNodeWithText("Domains").assertIsDisplayed()
    }

    @Test
    fun search_returns_ranked_results() {
        awaitText("A Book Of Life To Rebuild The World")

        rule.onNodeWithText("Search").performClick()
        rule.onNodeWithTag("search_input").performTextInput("water")

        rule.waitUntil(30_000) { hasText("results") }
        assertThat(hasText("results")).isTrue()
    }

    @Test
    fun opening_an_entry_renders_the_reader() {
        awaitText("A Book Of Life To Rebuild The World")
        rule.onNodeWithText("Search").performClick()
        rule.onNodeWithTag("search_input").performTextInput("charcoal production")
        awaitText("Charcoal Production")

        rule.onAllNodesWithText("Charcoal Production")[0].performClick()

        awaitText("Time to complete")
        rule.onNodeWithText("Time to complete", substring = true).assertIsDisplayed()
    }
}
