# frozen_string_literal: true

# The helpers that every template uses.
module ApplicationHelper
  # The interface string for a key.
  #
  # The strings come from the repository, in `i18n/strings/<lang>.yaml`, and
  # fall back to English when the active language does not define them.
  #
  # @param key [String] the catalogue key
  # @param params [Hash] the values of the `{placeholder}` fields
  # @return [String] the translated string
  def t(key, **params)
    translator.t(key, **params)
  end

  # The label of a safety level, for example `Caution`.
  #
  # @param level [String] the safety level
  # @return [String] the label
  def safety_label(level)
    t("safety_#{level}")
  end

  # The label of a difficulty level, for example `Journeyman`.
  #
  # @param level [String] the difficulty level
  # @return [String] the label
  def difficulty_label(level)
    t("difficulty_#{level}")
  end

  # The label of a verification status, for example `Field-Tested`.
  #
  # @param status [String] the verification status
  # @return [String] the label
  def verification_label(status)
    t("status_#{status.to_s.tr("-", "_")}")
  end

  # The name of a language, written in that language.
  #
  # @param code [String] the language code
  # @return [String] the display name
  def language_name(code)
    translator.language_name(code)
  end

  # The title of the page, built from the site name and the page heading.
  #
  # @param suffix [String, nil] the heading of the page
  # @return [String] the document title
  def page_title(suffix = nil)
    name = t("site_name")
    suffix.to_s.empty? ? name : "#{suffix} · #{name}"
  end

  # The text a search engine reads as the description of the page.
  #
  # @param text [String] the description
  # @return [String] the description
  def meta_description(text)
    text.to_s.gsub(/\s+/, " ").strip.truncate(300)
  end

  # The body of an entry, rendered as Markdown.
  #
  # @param entry [Entry] the entry
  # @return [String] an HTML fragment
  def entry_body(entry)
    markdown(entry.body)
  end

  # A navigation link that marks itself as the current page.
  #
  # @param label [String] the text of the link
  # @param path [String] the target of the link
  # @return [String] an HTML fragment
  def nav_link(label, path)
    current = current_page?(path)
    options = { class: current ? "nav-link is-current" : "nav-link" }
    options[:"aria-current"] = "page" if current
    link_to label, path, options
  end

  # The path of the current request, with its query string.
  #
  # @return [String] the path
  def current_path_with_query
    query = request.query_string
    query.to_s.empty? ? request.path : "#{request.path}?#{query}"
  end
end
