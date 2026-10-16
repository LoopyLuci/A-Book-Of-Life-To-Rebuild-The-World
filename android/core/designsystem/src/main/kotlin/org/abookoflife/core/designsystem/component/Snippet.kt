package org.abookoflife.core.designsystem.component

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.text.style.TextOverflow
import org.abookoflife.core.model.HIGHLIGHT_CLOSE
import org.abookoflife.core.model.HIGHLIGHT_OPEN

@Composable
fun HighlightedSnippet(text: String, modifier: Modifier = Modifier, maxLines: Int = 3) {
    val annotated = buildAnnotatedString {
        var index = 0
        while (index < text.length) {
            val open = text.indexOf(HIGHLIGHT_OPEN, index)
            if (open < 0) {
                append(text.substring(index))
                break
            }
            append(text.substring(index, open))
            val close = text.indexOf(HIGHLIGHT_CLOSE, open + 1)
            if (close < 0) {
                append(text.substring(open))
                break
            }
            val term = text.substring(open + 1, close)
            withStyle(SpanStyle(fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.primary)) {
                append(term)
            }
            index = close + 1
        }
    }
    Text(
        text = annotated,
        style = MaterialTheme.typography.bodySmall,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        maxLines = maxLines,
        overflow = TextOverflow.Ellipsis,
        modifier = modifier,
    )
}
