# frozen_string_literal: true

# A small, self-contained Markdown renderer.
#
# The renderer never trusts its input: every piece of text is HTML escaped
# before any markup is produced, so a knowledge entry can never inject markup
# into the page. Only the tags emitted by this module end up in the output.
#
# Supported syntax: ATX headings, paragraphs, ordered and unordered lists
# (including nesting), fenced code blocks, inline code, blockquotes,
# horizontal rules, pipe tables, links, bold, italic and strikethrough
# emphasis.
#
# Links are only turned into anchors for the `http`, `https` and `mailto`
# schemes. Every other target is rendered as plain text, which keeps a
# `javascript:` or `data:` URL from ever reaching an `href` attribute.
module Markdown
  ESCAPES = {
    "&" => "&amp;",
    "<" => "&lt;",
    ">" => "&gt;",
    '"' => "&quot;",
    "'" => "&#39;"
  }.freeze

  # The only schemes that are linkified.
  ALLOWED_SCHEMES = %w[http: https: mailto:].freeze

  # Private use characters used to park already rendered HTML.
  PLACEHOLDER_START = "\uE000"
  PLACEHOLDER_END = "\uE001"

  HEADING = /\A(\#{1,6})[ \t]+(.*?)[ \t]*\#*[ \t]*\z/
  RULE = /\A {0,3}([-*_])[ \t]*(?:\1[ \t]*){2,}\z/
  LIST_ITEM = /\A([ \t]*)([-*+]|\d{1,9}[.)])[ \t]+(.*)\z/
  FENCE = /\A([ \t]*)(`{3,}|~{3,})[ \t]*([^\s`]*)[ \t]*\z/
  QUOTE = /\A {0,3}>[ ]?/
  TABLE_DELIMITER = /\A[ \t]*\|?[ \t]*:?-+:?[ \t]*(?:\|[ \t]*:?-+:?[ \t]*)*\|?[ \t]*\z/
  SCHEME = /\A([a-zA-Z][a-zA-Z0-9+.\-]*):/
  CONTROL_CHARACTERS = /[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/
  WHITESPACE_PROBE = /[[:space:]]/

  # The blocks the parser produces.
  HeadingBlock = Data.define(:level, :text)
  ParagraphBlock = Data.define(:text)
  CodeBlock = Data.define(:language, :content)
  QuoteBlock = Data.define(:children)
  RuleBlock = Data.define(:marker)
  ListItem = Data.define(:children)
  ListBlock = Data.define(:ordered, :start, :tight, :items)
  TableBlock = Data.define(:header, :align, :rows)

  # The read cursor the parser shares between the block parsers.
  Cursor = Struct.new(:i)

  class << self
    # Render Markdown to an HTML fragment.
    #
    # @param source [String] the Markdown source
    # @return [String] an HTML fragment
    def render(source)
      text = source.to_s.gsub(/\r\n?/, "\n").gsub(CONTROL_CHARACTERS, "")
      text = text.delete(PLACEHOLDER_START + PLACEHOLDER_END)

      lines = text.split("\n", -1)
      cursor = Cursor.new(0)
      parse_blocks(lines, cursor).map { |block| render_block(block) }.join("\n")
    end

    # Render the inline (span level) part of a Markdown string.
    #
    # @param text [String] the inline source
    # @param escaped [Boolean] true when the text has already been escaped
    # @return [String] an HTML fragment
    def render_inline(text, escaped: false)
      stash = []
      out = escaped ? text.to_s : escape(text)
      out = extract_code_spans(out, stash)
      out = extract_links(out, stash)
      out = apply_emphasis(out)
      out.gsub(/#{PLACEHOLDER_START}(\d+)#{PLACEHOLDER_END}/) { stash[Regexp.last_match(1).to_i].to_s }
    end

    # Escape the five characters that matter inside HTML text and attributes.
    #
    # @param text [String] the text to escape
    # @return [String] the escaped text
    def escape(text)
      text.to_s.gsub(/[&<>"']/) { |char| ESCAPES[char] }
    end

    # The link target that is safe to put in an `href` attribute, or nil when
    # the target must not be linked.
    #
    # Only the `http`, `https` and `mailto` schemes are allowed. A target
    # without a scheme is a relative reference and is not linkified either.
    #
    # @param raw [String] the raw link target
    # @return [String, nil] the target, or nil
    def safe_href(raw)
      trimmed = raw.to_s.strip
      return nil if trimmed.empty?

      probe = trimmed.gsub(WHITESPACE_PROBE, "").gsub(CONTROL_CHARACTERS, "")
      return nil if probe.start_with?("//")

      match = SCHEME.match(probe)
      return nil if match.nil?
      return nil unless ALLOWED_SCHEMES.include?("#{match[1].downcase}:")

      trimmed
    end

    # Turn a heading into a stable anchor id.
    #
    # @param text [String] the heading text
    # @return [String] a slug suitable for an `id` attribute
    def slugify(text)
      text.to_s.downcase
          .gsub(/[^a-z0-9\u00C0-\u024F]+/, "-")
          .gsub(/\A-+/, "")
          .gsub(/-+\z/, "")
    end

    private

    # ------------------------------------------------------------------
    # Inline parsing
    # ------------------------------------------------------------------

    def extract_code_spans(text, stash)
      out = +""
      index = 0

      while index < text.length
        char = text[index]
        unless char == "`"
          out << char
          index += 1
          next
        end

        run_end = index
        run_end += 1 while text[run_end] == "`"
        run_length = run_end - index
        closing = text.index("`" * run_length, run_end)

        if closing.nil?
          out << text[index...run_end]
          index = run_end
          next
        end

        code = text[run_end...closing]
        if code.length > 1 && code.start_with?(" ") && code.end_with?(" ") && !code.strip.empty?
          code = code[1...-1]
        end

        out << stash_html("<code>#{code}</code>", stash)
        index = closing + run_length
      end

      out
    end

    def extract_links(text, stash)
      out = +""
      index = 0

      while index < text.length
        char = text[index]
        unless char == "["
          out << char
          index += 1
          next
        end

        label_end = find_closing(text, index, "[", "]")
        if label_end.nil?
          out << char
          index += 1
          next
        end

        if text[label_end + 1] != "("
          out << text[index..label_end]
          index = label_end + 1
          next
        end

        target_end = find_closing(text, label_end + 1, "(", ")")
        if target_end.nil?
          out << text[index..label_end]
          index = label_end + 1
          next
        end

        label = text[(index + 1)...label_end].to_s
        destination = text[(label_end + 2)...target_end].to_s.strip
        href = if destination.start_with?("<") && destination.end_with?(">")
                 destination[1...-1]
               else
                 destination.split(/\s+/).first.to_s
               end

        target = safe_href(href)
        if target.nil?
          out << stash_html(%(<span class="md-link-unresolved">#{render_inline(label, escaped: true)}</span>), stash)
        else
          attributes = target.match?(%r{\Ahttps?://}) ? ' target="_blank" rel="noopener noreferrer"' : ""
          out << stash_html(%(<a href="#{target}"#{attributes}>#{render_inline(label, escaped: true)}</a>), stash)
        end

        index = target_end + 1
      end

      out
    end

    def find_closing(text, start, open_char, close_char)
      depth = 0
      index = start

      while index < text.length
        char = text[index]
        if char == open_char
          depth += 1
        elsif char == close_char
          depth -= 1
          return index if depth.zero?
        end
        index += 1
      end

      nil
    end

    def apply_emphasis(text)
      text
        .gsub(/\*\*\*([^*]+)\*\*\*/, '<strong><em>\1</em></strong>')
        .gsub(/\*\*([^*\n]+)\*\*/, '<strong>\1</strong>')
        .gsub(/__([^_\n]+)__/, '<strong>\1</strong>')
        .gsub(/\*([^*\n]+)\*/, '<em>\1</em>')
        .gsub(/(^|[^\w])_([^_\n]+)_(?!\w)/, '\1<em>\2</em>')
        .gsub(/~~([^~\n]+)~~/, '<del>\1</del>')
    end

    def stash_html(html, stash)
      stash << html
      "#{PLACEHOLDER_START}#{stash.size - 1}#{PLACEHOLDER_END}"
    end

    # ------------------------------------------------------------------
    # Block parsing
    # ------------------------------------------------------------------

    def parse_blocks(lines, cursor)
      blocks = []

      while cursor.i < lines.size
        line = lines[cursor.i]

        if line.strip.empty?
          cursor.i += 1
          next
        end

        fence = FENCE.match(line)
        if fence
          blocks << parse_fenced_code(lines, cursor, fence[2], fence[3])
          next
        end

        heading = HEADING.match(line)
        if heading
          cursor.i += 1
          blocks << HeadingBlock.new(level: heading[1].length, text: heading[2])
          next
        end

        if RULE.match?(line)
          cursor.i += 1
          blocks << RuleBlock.new(marker: "-")
          next
        end

        if QUOTE.match?(line)
          blocks << parse_quote(lines, cursor)
          next
        end

        if line.include?("|") && table_delimiter?(lines[cursor.i + 1].to_s)
          blocks << parse_table(lines, cursor)
          next
        end

        if LIST_ITEM.match?(line)
          blocks << parse_list(lines, cursor)
          next
        end

        blocks << parse_paragraph(lines, cursor)
      end

      blocks
    end

    def parse_fenced_code(lines, cursor, marker, language)
      cursor.i += 1
      closing = /\A {0,3}#{Regexp.escape(marker[0])}{#{marker.length},}[ \t]*\z/
      content = []

      while cursor.i < lines.size
        current = lines[cursor.i]
        if closing.match?(current)
          cursor.i += 1
          break
        end
        content << current
        cursor.i += 1
      end

      CodeBlock.new(language: language.to_s, content: content.join("\n"))
    end

    def parse_quote(lines, cursor)
      inner = []

      while cursor.i < lines.size
        line = lines[cursor.i]
        break unless QUOTE.match?(line)

        inner << line.sub(QUOTE, "")
        cursor.i += 1
      end

      QuoteBlock.new(children: parse_blocks(inner, Cursor.new(0)))
    end

    def parse_paragraph(lines, cursor)
      parts = []

      while cursor.i < lines.size
        line = lines[cursor.i]
        break if line.strip.empty?
        break if !parts.empty? && starts_new_block?(line, lines[cursor.i + 1].to_s)

        parts << line.strip
        cursor.i += 1
      end

      ParagraphBlock.new(text: parts.join("\n"))
    end

    def starts_new_block?(line, next_line)
      return true if HEADING.match?(line)
      return true if RULE.match?(line)
      return true if FENCE.match?(line)
      return true if QUOTE.match?(line)
      return true if LIST_ITEM.match?(line)
      return true if line.include?("|") && table_delimiter?(next_line)

      false
    end

    def table_delimiter?(line)
      !line.strip.empty? && line.include?("-") && TABLE_DELIMITER.match?(line)
    end

    def parse_table(lines, cursor)
      header = split_row(lines[cursor.i].to_s)
      cursor.i += 1
      delimiter = split_row(lines[cursor.i].to_s)
      cursor.i += 1

      align = delimiter.map do |cell|
        left = cell.start_with?(":")
        right = cell.end_with?(":")
        if left && right then "center"
        elsif right then "right"
        elsif left then "left"
        end
      end

      rows = []
      while cursor.i < lines.size
        line = lines[cursor.i]
        break if line.strip.empty? || !line.include?("|")

        rows << split_row(line)
        cursor.i += 1
      end

      TableBlock.new(header: header, align: align, rows: rows)
    end

    def split_row(line)
      text = line.strip
      text = text[1..] if text.start_with?("|")
      text = text[0...-1] if text.end_with?("|") && !text.end_with?("\\|")

      cells = []
      current = +""
      in_code = false
      index = 0

      while index < text.length
        char = text[index]

        if char == "\\" && text[index + 1] == "|"
          current << "|"
          index += 2
          next
        end

        in_code = !in_code if char == "`"

        if char == "|" && !in_code
          cells << current.strip
          current = +""
          index += 1
          next
        end

        current << char
        index += 1
      end

      cells << current.strip
      cells
    end

    def parse_list(lines, cursor)
      first = LIST_ITEM.match(lines[cursor.i].to_s)
      list_indent = first[1].length
      ordered = first[2].match?(/\d/)
      start = ordered ? first[2].to_i : 1
      marker_char = first[2].gsub(/[0-9.]/, "")

      items = []
      tight = true

      while cursor.i < lines.size
        line = lines[cursor.i]

        if line.strip.empty?
          look = skip_blank(lines, cursor.i)
          after = look < lines.size ? lines[look] : nil
          if after && LIST_ITEM.match?(after) && indent_width(after) == list_indent &&
             same_list_type?(after, ordered, marker_char)
            tight = false
            cursor.i = look
            next
          end
          break
        end

        match = LIST_ITEM.match(line)
        break if match.nil?

        marker = match[2]
        break if marker.match?(/\d/) != ordered
        break unless marker.gsub(/[0-9.]/, "") == marker_char
        break unless indent_width(line) == list_indent

        content = match[3]
        after_marker = line[(indent_width(line) + marker.length)..].to_s
        content_column = indent_width(line) + marker.length + (after_marker.length - after_marker.lstrip.length)

        item_lines = [content]
        cursor.i += 1

        while cursor.i < lines.size
          following = lines[cursor.i]

          if following.strip.empty?
            look = skip_blank(lines, cursor.i)
            after = look < lines.size ? lines[look] : nil
            if after && indent_width(after) > indent_width(line)
              (cursor.i...look).each { |index| item_lines << "" }
              cursor.i = look
              tight = false
              next
            end
            break
          end

          following_indent = indent_width(following)
          if following_indent > indent_width(line)
            item_lines << following[[following_indent, content_column].min..].to_s
            cursor.i += 1
            next
          end

          break if following_indent == indent_width(line) && LIST_ITEM.match?(following)

          item_lines << following.strip
          cursor.i += 1
        end

        items << ListItem.new(children: parse_blocks(item_lines, Cursor.new(0)))
      end

      ListBlock.new(ordered: ordered, start: start, tight: tight, items: items)
    end

    def skip_blank(lines, from)
      index = from
      index += 1 while index < lines.size && lines[index].strip.empty?
      index
    end

    # Whether a line continues the list that is being parsed.
    #
    # A blank line only makes a list loose when the list continues with the
    # same kind of item. A blank line between an unordered list and an ordered
    # one starts a new list and leaves the first one tight.
    def same_list_type?(line, ordered, marker_char)
      match = LIST_ITEM.match(line)
      return false if match.nil?

      marker = match[2]
      marker.match?(/\d/) == ordered && marker.gsub(/[0-9.]/, "") == marker_char
    end

    def indent_width(line)
      line.length - line.lstrip.length
    end

    # ------------------------------------------------------------------
    # Block rendering
    # ------------------------------------------------------------------

    def render_block(block)
      case block
      when HeadingBlock
        level = block.level.clamp(1, 6)
        %(<h#{level} id="#{slugify(block.text)}">#{render_inline(block.text)}</h#{level}>)
      when ParagraphBlock
        "<p>#{render_inline(block.text)}</p>"
      when CodeBlock
        language = block.language.gsub(/[^A-Za-z0-9_+-]/, "")
        class_name = language.empty? ? "" : %( class="language-#{language}")
        "<pre><code#{class_name}>#{escape(block.content)}</code></pre>"
      when QuoteBlock
        children = block.children.map { |child| render_block(child) }.join("\n")
        "<blockquote>#{children}</blockquote>"
      when RuleBlock
        "<hr>"
      when ListBlock
        tag = block.ordered ? "ol" : "ul"
        start_attribute = block.ordered && block.start != 1 ? %( start="#{block.start}") : ""
        items = block.items.map { |item| render_list_item(item, block.tight) }.join("\n")
        "<#{tag}#{start_attribute}>\n#{items}\n</#{tag}>"
      when TableBlock
        render_table(block)
      else
        ""
      end
    end

    def render_list_item(item, tight)
      parts = item.children.each_with_index.map do |child, index|
        if tight && index.zero? && child.is_a?(ParagraphBlock)
          %(<p class="md-tight">#{render_inline(child.text)}</p>)
        else
          render_block(child)
        end
      end
      "<li>#{parts.join("\n")}</li>"
    end

    def render_table(block)
      head = block.header.each_with_index.map do |cell, index|
        %(<th#{align_attribute(block.align[index])}>#{render_inline(cell)}</th>)
      end.join

      rows = block.rows.map do |row|
        cells = block.header.each_index.map do |index|
          %(<td#{align_attribute(block.align[index])}>#{render_inline(row[index].to_s)}</td>)
        end.join
        "<tr>#{cells}</tr>"
      end.join("\n")

      %(<div class="table-scroll"><table><thead><tr>#{head}</tr></thead><tbody>\n#{rows}\n</tbody></table></div>)
    end

    # The alignment of a table cell is expressed with a class rather than an
    # inline style, so that a strict content security policy stays possible.
    def align_attribute(align)
      align ? %( class="align-#{align}") : ""
    end
  end
end
