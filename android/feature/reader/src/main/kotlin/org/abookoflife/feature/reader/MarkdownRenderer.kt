package org.abookoflife.feature.reader

import androidx.compose.foundation.background
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.AnnotatedString
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import org.intellij.markdown.IElementType
import org.intellij.markdown.MarkdownElementTypes
import org.intellij.markdown.MarkdownTokenTypes
import org.intellij.markdown.ast.ASTNode
import org.intellij.markdown.ast.getTextInNode
import org.intellij.markdown.flavours.gfm.GFMElementTypes
import org.intellij.markdown.flavours.gfm.GFMFlavourDescriptor
import org.intellij.markdown.parser.MarkdownParser

private val markerTokens: Set<IElementType> = setOf(
    MarkdownTokenTypes.EMPH,
    MarkdownTokenTypes.ATX_HEADER,
    MarkdownTokenTypes.SETEXT_1,
    MarkdownTokenTypes.SETEXT_2,
    MarkdownTokenTypes.LIST_BULLET,
    MarkdownTokenTypes.LIST_NUMBER,
    MarkdownTokenTypes.BLOCK_QUOTE,
    MarkdownTokenTypes.BACKTICK,
    MarkdownTokenTypes.ESCAPED_BACKTICKS,
    MarkdownTokenTypes.LBRACKET,
    MarkdownTokenTypes.RBRACKET,
    MarkdownTokenTypes.LPAREN,
    MarkdownTokenTypes.RPAREN,
    MarkdownTokenTypes.EXCLAMATION_MARK,
    MarkdownTokenTypes.HORIZONTAL_RULE,
    MarkdownTokenTypes.CODE_FENCE_START,
    MarkdownTokenTypes.CODE_FENCE_END,
    MarkdownTokenTypes.FENCE_LANG,
    MarkdownTokenTypes.LINK_ID,
)

@Composable
fun MarkdownText(
    markdown: String,
    modifier: Modifier = Modifier,
    bodyStyle: TextStyle = MaterialTheme.typography.bodyLarge,
) {
    val flavour = remember { GFMFlavourDescriptor() }
    val tree = remember(markdown) {
        MarkdownParser(flavour).buildMarkdownTreeFromString(markdown)
    }
    Column(modifier = modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
        tree.children.forEach { child -> MarkdownBlock(child, markdown, bodyStyle) }
    }
}

@Composable
private fun MarkdownBlock(node: ASTNode, text: String, bodyStyle: TextStyle) {
    when (node.type) {
        MarkdownElementTypes.ATX_1, MarkdownElementTypes.SETEXT_1 ->
            Heading(node, text, MaterialTheme.typography.headlineMedium)

        MarkdownElementTypes.ATX_2, MarkdownElementTypes.SETEXT_2 ->
            Heading(node, text, MaterialTheme.typography.headlineSmall)

        MarkdownElementTypes.ATX_3 ->
            Heading(node, text, MaterialTheme.typography.titleLarge)

        MarkdownElementTypes.ATX_4,
        MarkdownElementTypes.ATX_5,
        MarkdownElementTypes.ATX_6,
        -> Heading(node, text, MaterialTheme.typography.titleMedium)

        MarkdownElementTypes.PARAGRAPH -> InlineParagraph(node, text, bodyStyle)

        MarkdownElementTypes.BLOCK_QUOTE -> BlockQuote(node, text, bodyStyle)

        MarkdownElementTypes.UNORDERED_LIST -> ListBlock(node, text, bodyStyle, ordered = false)

        MarkdownElementTypes.ORDERED_LIST -> ListBlock(node, text, bodyStyle, ordered = true)

        MarkdownElementTypes.CODE_FENCE, MarkdownElementTypes.CODE_BLOCK -> CodeBlock(node, text)

        MarkdownTokenTypes.HORIZONTAL_RULE -> HorizontalDivider()

        MarkdownElementTypes.LINK_DEFINITION, MarkdownElementTypes.MARKDOWN_FILE -> Unit

        GFMElementTypes.TABLE -> TableBlock(node, text)

        else -> InlineParagraph(node, text, bodyStyle)
    }
}

@Composable
private fun Heading(node: ASTNode, text: String, style: TextStyle) {
    Text(
        text = buildInline(node, text, style.color, MaterialTheme.colorScheme.onBackground),
        style = style,
        color = MaterialTheme.colorScheme.onBackground,
    )
}

@Composable
private fun InlineParagraph(node: ASTNode, text: String, bodyStyle: TextStyle) {
    Text(
        text = buildInline(node, text, MaterialTheme.colorScheme.primary, bodyStyle.color),
        style = bodyStyle,
        color = MaterialTheme.colorScheme.onBackground,
    )
}

@Composable
private fun BlockQuote(node: ASTNode, text: String, bodyStyle: TextStyle) {
    Row(
        modifier = Modifier.height(IntrinsicSize.Min),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier
                .width(3.dp)
                .fillMaxHeight()
                .background(
                    MaterialTheme.colorScheme.primary.copy(alpha = 0.45f),
                    RoundedCornerShape(2.dp),
                ),
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            node.children
                .filter { it.type != MarkdownTokenTypes.BLOCK_QUOTE }
                .forEach { child -> MarkdownBlock(child, text, bodyStyle) }
        }
    }
}

@Composable
private fun ListBlock(node: ASTNode, text: String, bodyStyle: TextStyle, ordered: Boolean) {
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        node.children
            .filter { it.type == MarkdownElementTypes.LIST_ITEM }
            .forEach { item -> ListItem(item, text, bodyStyle, ordered) }
    }
}

@Composable
private fun ListItem(item: ASTNode, text: String, bodyStyle: TextStyle, ordered: Boolean) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        val markerNode = item.children.firstOrNull {
            it.type == MarkdownTokenTypes.LIST_BULLET || it.type == MarkdownTokenTypes.LIST_NUMBER
        }
        val marker = if (ordered) {
            markerNode?.getTextInNode(text)?.toString()?.trim().orEmpty()
        } else {
            "•"
        }
        Text(
            text = marker,
            style = bodyStyle,
            color = MaterialTheme.colorScheme.primary,
            modifier = Modifier.width(if (ordered) 26.dp else 16.dp),
        )
        Column(
            modifier = Modifier.weight(1f),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            item.children
                .filter {
                    it.type != MarkdownTokenTypes.LIST_BULLET &&
                        it.type != MarkdownTokenTypes.LIST_NUMBER
                }
                .forEach { child -> MarkdownBlock(child, text, bodyStyle) }
        }
    }
}

@Composable
private fun CodeBlock(node: ASTNode, text: String) {
    val content = node.children
        .filter {
            it.type == MarkdownTokenTypes.CODE_FENCE_CONTENT ||
                it.type == MarkdownTokenTypes.CODE_LINE
        }
        .joinToString("\n") { it.getTextInNode(text).toString() }
        .trim('\n')

    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = MaterialTheme.shapes.small,
    ) {
        Text(
            text = content,
            style = MaterialTheme.typography.bodySmall,
            fontFamily = FontFamily.Monospace,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(12.dp),
        )
    }
}

@Composable
private fun TableBlock(node: ASTNode, text: String) {
    Surface(
        color = MaterialTheme.colorScheme.surfaceVariant,
        shape = MaterialTheme.shapes.small,
    ) {
        Text(
            text = node.getTextInNode(text).toString().trim(),
            style = MaterialTheme.typography.bodySmall,
            fontFamily = FontFamily.Monospace,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
            modifier = Modifier
                .horizontalScroll(rememberScrollState())
                .padding(12.dp),
        )
    }
}

private fun buildInline(
    node: ASTNode,
    text: String,
    linkColor: androidx.compose.ui.graphics.Color,
    baseColor: androidx.compose.ui.graphics.Color,
): AnnotatedString {
    val builder = AnnotatedString.Builder()
    appendInline(builder, node, text, SpanStyle(color = baseColor), linkColor)
    return builder.toAnnotatedString()
}

private fun appendInline(
    builder: AnnotatedString.Builder,
    node: ASTNode,
    text: String,
    style: SpanStyle,
    linkColor: androidx.compose.ui.graphics.Color,
) {
    val children = node.children
    if (children.isEmpty()) {
        when (node.type) {
            in markerTokens -> Unit
            MarkdownTokenTypes.EOL -> builder.append(" ")
            MarkdownTokenTypes.HARD_LINE_BREAK -> builder.append("\n")
            else -> builder.withStyle(style) { append(node.getTextInNode(text)) }
        }
        return
    }

    when (node.type) {
        MarkdownElementTypes.STRONG -> {
            val merged = style.merge(SpanStyle(fontWeight = FontWeight.Bold))
            children.forEach { appendInline(builder, it, text, merged, linkColor) }
        }

        MarkdownElementTypes.EMPH -> {
            val merged = style.merge(SpanStyle(fontStyle = FontStyle.Italic))
            children.forEach { appendInline(builder, it, text, merged, linkColor) }
        }

        MarkdownElementTypes.CODE_SPAN -> {
            val merged = style.merge(SpanStyle(fontFamily = FontFamily.Monospace))
            children.forEach { appendInline(builder, it, text, merged, linkColor) }
        }

        GFMElementTypes.STRIKETHROUGH -> {
            val merged = style.merge(SpanStyle(textDecoration = TextDecoration.LineThrough))
            children.forEach { appendInline(builder, it, text, merged, linkColor) }
        }

        MarkdownElementTypes.INLINE_LINK,
        MarkdownElementTypes.FULL_REFERENCE_LINK,
        MarkdownElementTypes.SHORT_REFERENCE_LINK,
        MarkdownElementTypes.AUTOLINK,
        -> {
            val linkStyle = style.merge(
                SpanStyle(color = linkColor, textDecoration = TextDecoration.Underline),
            )
            val linkText = children.firstOrNull { it.type == MarkdownElementTypes.LINK_TEXT }
            if (linkText != null) {
                appendInline(builder, linkText, text, linkStyle, linkColor)
            } else {
                builder.withStyle(linkStyle) { append(node.getTextInNode(text)) }
            }
        }

        MarkdownElementTypes.IMAGE -> {
            val alt = children.firstOrNull { it.type == MarkdownElementTypes.LINK_TEXT }
            if (alt != null) appendInline(builder, alt, text, style, linkColor)
        }

        else -> children.forEach { appendInline(builder, it, text, style, linkColor) }
    }
}
