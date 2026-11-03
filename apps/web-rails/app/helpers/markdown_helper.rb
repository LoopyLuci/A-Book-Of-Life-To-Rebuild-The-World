# frozen_string_literal: true

# The view helpers that expose the Markdown renderer to the templates.
module MarkdownHelper
  # Render a Markdown document to an HTML fragment.
  #
  # The renderer escapes every piece of text before it produces any markup,
  # and it only ever emits the tags it generates itself, so the result is
  # safe to put in a page.
  #
  # @param source [String] the Markdown source
  # @return [String] an HTML fragment
  def markdown(source)
    Markdown.render(source).html_safe
  end

  # Render the inline part of a Markdown string.
  #
  # @param source [String] the inline source
  # @return [String] an HTML fragment
  def markdown_inline(source)
    Markdown.render_inline(source).html_safe
  end
end
