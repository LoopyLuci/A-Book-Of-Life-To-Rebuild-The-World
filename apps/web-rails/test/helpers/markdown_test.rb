require "test_helper"

# The Markdown renderer, and above all its escaping.
class MarkdownTest < ActiveSupport::TestCase
  test "renders headings" do
    assert_equal %(<h1 id="title">Title</h1>), Markdown.render("# Title")
    assert_equal %(<h3 id="sub-heading">Sub heading</h3>), Markdown.render("### Sub heading")
  end

  test "renders paragraphs" do
    assert_equal "<p>Hello world</p>", Markdown.render("Hello world")
    assert_equal "<p>One\ntwo</p>", Markdown.render("One\ntwo")
  end

  test "renders unordered lists" do
    html = Markdown.render("- one\n- two")

    assert_includes html, "<ul>"
    assert_includes html, "<li>"
    assert_includes html, "one"
  end

  test "renders ordered lists" do
    html = Markdown.render("1. one\n2. two")

    assert_includes html, "<ol>"
    assert_includes html, "<li>"
  end

  test "renders nested lists" do
    html = Markdown.render("- one\n  - nested")

    assert_equal 2, html.scan("<ul>").size
    assert_includes html, "nested"
  end

  test "renders blockquotes" do
    assert_equal "<blockquote><p>quoted</p></blockquote>", Markdown.render("> quoted")
  end

  test "renders code blocks" do
    assert_equal "<pre><code>puts 1</code></pre>", Markdown.render("```\nputs 1\n```")
    assert_includes Markdown.render("```ruby\nputs 1\n```"), %(class="language-ruby")
  end

  test "renders inline code" do
    assert_equal "<p><code>puts 1</code></p>", Markdown.render("`puts 1`")
  end

  test "renders emphasis" do
    assert_equal "<p><em>italic</em></p>", Markdown.render("*italic*")
    assert_equal "<p><strong>bold</strong></p>", Markdown.render("**bold**")
    assert_equal "<p><strong><em>both</em></strong></p>", Markdown.render("***both***")
  end

  test "renders tables" do
    html = Markdown.render("| A | B |\n|---|---|\n| 1 | 2 |")

    assert_includes html, "<table>"
    assert_includes html, "<th>A</th>"
    assert_includes html, "<td>2</td>"
  end

  test "escapes html so that content cannot inject markup" do
    html = Markdown.render(%(<script>alert("xss")</script>))

    refute_includes html, "<script>"
    assert_includes html, "&lt;script&gt;"
    assert_includes html, "&quot;"
  end

  test "escapes html in a paragraph, a heading and a list" do
    refute_includes Markdown.render(%(<img src=x onerror=alert(1)>)), "<img"
    refute_includes Markdown.render(%(# <b>bold</b>)), "<b>"
    refute_includes Markdown.render(%(- <b>bold</b>)), "<b>"
    refute_includes Markdown.render(%(> <b>bold</b>)), "<b>"
  end

  test "escapes html inside a code block" do
    html = Markdown.render("```\n<script>alert(1)</script>\n```")

    refute_includes html, "<script>"
    assert_includes html, "&lt;script&gt;"
  end

  test "escapes html inside a link label" do
    html = Markdown.render(%([<b>x</b>](https://example.com)))

    refute_includes html, "<b>"
    assert_includes html, "&lt;b&gt;"
  end

  test "only linkifies http, https and mailto" do
    assert_includes Markdown.render("[x](https://example.com)"), %(<a href="https://example.com")
    assert_includes Markdown.render("[x](http://example.com)"), %(<a href="http://example.com")
    assert_includes Markdown.render("[x](mailto:a@example.com)"), %(<a href="mailto:a@example.com")
  end

  test "does not linkify a dangerous or a relative target" do
    refute_includes Markdown.render("[x](javascript:alert(1))"), "<a "
    refute_includes Markdown.render("[x](data:text/html;base64,PHN2Zz4=)"), "<a "
    refute_includes Markdown.render("[x](vbscript:msgbox(1))"), "<a "
    refute_includes Markdown.render("[x](./relative.md)"), "<a "
    refute_includes Markdown.render("[x](#anchor)"), "<a "
    refute_includes Markdown.render("[x](/absolute/path)"), "<a "
  end

  test "a link cannot break out of the href attribute" do
    html = Markdown.render(%([x](https://example.com/"onmouseover="alert)))

    refute_includes html, %("onmouseover=)
    assert_includes html, "&quot;"
  end

  test "a link target with white space cannot smuggle a scheme" do
    html = Markdown.render("[x](java\tscript:alert(1))")

    refute_includes html, "<a "
  end

  test "renders a horizontal rule" do
    assert_equal "<hr>", Markdown.render("---")
  end

  test "escapes the ampersand in ordinary text" do
    assert_equal "<p>this &amp; that</p>", Markdown.render("this & that")
  end

  test "produces a stable anchor id for a heading" do
    assert_equal "safety-notes", Markdown.slugify("Safety Notes")
    assert_equal "method-1-ferro-rod", Markdown.slugify("Method 1: Ferro Rod")
  end
end
