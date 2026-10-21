package org.abookoflife.feature.reader

import android.content.Context
import android.content.Intent
import android.net.Uri
import org.abookoflife.core.model.Source

/**
 * Opens a citation. Uses the source's URL when one is on file; otherwise falls
 * back to a web search for the exact title so every source remains actionable
 * without inventing links that may not exist.
 */
fun openSource(context: Context, source: Source) {
    val url = source.url?.trim().orEmpty()
    if (url.startsWith("http://") || url.startsWith("https://")) {
        openUrl(context, url)
    } else {
        openUrl(context, "https://duckduckgo.com/?q=" + Uri.encode(source.title))
    }
}

/** Opens an external URL, ignoring targets the device cannot handle. */
fun openUrl(context: Context, url: String) {
    val uri = runCatching { Uri.parse(url) }.getOrNull() ?: return
    val intent = Intent(Intent.ACTION_VIEW, uri)
    runCatching { context.startActivity(intent) }
}

/** Maps an in-book markdown link such as `making-fire.md` to its entry slug. */
fun markdownLinkSlug(target: String): String = target
    .substringBefore('#')
    .substringBefore('?')
    .substringAfterLast('/')
    .removeSuffix(".md")
    .trim()
