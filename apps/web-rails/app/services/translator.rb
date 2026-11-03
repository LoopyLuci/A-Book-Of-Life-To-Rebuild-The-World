# frozen_string_literal: true

require "yaml"
require "pathname"

# The interface strings of the application.
#
# The catalogues live in the repository, in `i18n/strings/<lang>.yaml`.
# `en.yaml` is the canonical catalogue; every other catalogue falls back to it
# for the keys it does not define, so a missing translation never leaves the
# reader with a blank label.
class Translator
  CANONICAL_LANGUAGES = %w[en es fr de pt hi ar sw zh id it ja ko nl ru tr vi].freeze
  FALLBACK_LANGUAGE = "en"

  LANGUAGE_NAMES = {
    "en" => "English",
    "es" => "Español",
    "fr" => "Français",
    "de" => "Deutsch",
    "pt" => "Português",
    "hi" => "हिन्दी",
    "ar" => "العربية",
    "sw" => "Kiswahili",
    "zh" => "中文",
    "id" => "Bahasa Indonesia",
    "it" => "Italiano",
    "ja" => "日本語",
    "ko" => "한국어",
    "nl" => "Nederlands",
    "ru" => "Русский",
    "tr" => "Türkçe",
    "vi" => "Tiếng Việt"
  }.freeze

  RIGHT_TO_LEFT_LANGUAGES = %w[ar].freeze

  # The English strings the interface needs, used when no catalogue can be
  # read at all. The keys mirror `i18n/strings/en.yaml`.
  DEFAULT_STRINGS = {
    "site_name" => "A Book Of Life To Rebuild The World",
    "tagline" => "An offline-first knowledge base for rebuilding civilization.",
    "search_placeholder" => "Search {count} entries…",
    "domains" => "Domains",
    "entries" => "Entries",
    "difficulty" => "Difficulty",
    "safety" => "Safety",
    "time_to_complete" => "Time to complete",
    "prerequisites" => "Prerequisites",
    "materials" => "Materials & Tools",
    "procedure" => "Procedure",
    "safety_notes" => "Safety Notes",
    "verification" => "Verification",
    "sources" => "Sources",
    "status_draft" => "Draft",
    "status_peer_reviewed" => "Peer-Reviewed",
    "status_field_tested" => "Field-Tested",
    "status_deprecated" => "Deprecated",
    "safety_green" => "Safe",
    "safety_yellow" => "Caution",
    "safety_red" => "Danger",
    "search" => "Search",
    "filter_domain" => "Domain",
    "filter_safety" => "Safety",
    "filter_difficulty" => "Difficulty",
    "all_domains" => "All domains",
    "all_safety_levels" => "All safety levels",
    "all_difficulty_levels" => "All difficulty levels",
    "language" => "Language",
    "theme" => "Theme",
    "theme_light" => "Light",
    "theme_dark" => "Dark",
    "theme_system" => "Follow the system",
    "about" => "About",
    "version" => "Version",
    "recently_read" => "Recently read",
    "results" => "Results",
    "no_results" => "No matching entries",
    "result_count" => "{count} results",
    "entry_count" => "{count} entries",
    "domain_entry_count" => "{count} entries in this domain",
    "domain_overview" => "Domain overview",
    "tags" => "Tags",
    "path" => "Path",
    "disclaimer" => "Disclaimer",
    "disclaimer_full" => "The full disclaimer is in docs/DISCLAIMER.md.",
    "related_entries" => "Related entries",
    "search_results_for" => "Results for “{query}”",
    "browse_all_entries" => "Browse all entries",
    "not_found_title" => "Page not found",
    "not_found_body" => "There is no page at this address. It may have been renamed.",
    "skip_to_content" => "Skip to main content",
    "home" => "Home",
    "apply" => "Apply",
    "loading_failed" => "The corpus could not be loaded: {error}",
    "difficulty_novice" => "Novice",
    "difficulty_apprentice" => "Apprentice",
    "difficulty_journeyman" => "Journeyman",
    "difficulty_master" => "Master"
  }.freeze

  attr_reader :strings_dir, :language, :fallback_language

  # @param strings_dir [String, Pathname] the directory holding `<lang>.yaml`
  # @param language [String] the language to start in
  # @param fallback_language [String] the language used for missing keys
  def initialize(strings_dir:, language: FALLBACK_LANGUAGE, fallback_language: FALLBACK_LANGUAGE)
    @strings_dir = Pathname.new(strings_dir.to_s)
    @fallback_language = fallback_language.to_s
    @fallback_strings = load_catalogue(@fallback_language)
    @strings = {}
    @language = @fallback_language
    set_language(language)
  end

  # Switch to another language.
  #
  # @param language [String] the language code, for example `fr`
  # @return [Boolean] true when the requested catalogue was loaded, false when
  #   the fallback language was used instead
  def set_language(language)
    code = language.to_s.downcase
    catalogue = load_catalogue(code)

    if catalogue.empty? && code != @fallback_language
      @language = @fallback_language
      @strings = @fallback_strings.dup
      return false
    end

    @language = code
    @strings = catalogue
    true
  end

  # The string for a key.
  #
  # The current language wins, then the fallback language, then the built-in
  # English defaults, and finally the key itself, so that a missing string is
  # visible but never fatal.
  #
  # @param key [String] the catalogue key
  # @param params [Hash] the values of the `{placeholder}` fields
  # @return [String] the translated string
  def t(key, **params)
    value = @strings[key.to_s]
    value = @fallback_strings[key.to_s] if value.nil?
    value = DEFAULT_STRINGS[key.to_s] if value.nil?
    return key.to_s if value.nil?

    interpolate(value, params)
  end

  # The languages the reader can switch to.
  #
  # A language is offered when its catalogue file exists. The canonical order
  # is preserved and any extra language is appended alphabetically.
  #
  # @return [Array<String>] the language codes
  def available_languages
    found = []
    Dir.glob(strings_dir.join("*.yaml")).sort.each do |path|
      code = File.basename(path, ".yaml").downcase
      found << code unless found.include?(code)
    end

    ordered = CANONICAL_LANGUAGES.select { |code| found.include?(code) }
    ordered += (found - CANONICAL_LANGUAGES).sort
    ordered = [FALLBACK_LANGUAGE] + ordered unless ordered.include?(FALLBACK_LANGUAGE)
    ordered
  end

  # The name of a language, written in that language.
  #
  # @param code [String] the language code
  # @return [String] the display name
  def language_name(code)
    LANGUAGE_NAMES.fetch(code.to_s, code.to_s)
  end

  # Whether a language is written from right to left.
  #
  # @param code [String] the language code
  # @return [Boolean] true for right to left languages
  def right_to_left?(code = language)
    RIGHT_TO_LEFT_LANGUAGES.include?(code.to_s)
  end

  private

  def interpolate(value, params)
    return value if params.empty?

    value.gsub(/\{(\w+)\}/) do
      key = Regexp.last_match(1)
      if params.key?(key.to_sym)
        params[key.to_sym].to_s
      elsif params.key?(key)
        params[key].to_s
      else
        "{#{key}}"
      end
    end
  end

  def load_catalogue(language)
    code = language.to_s.downcase
    return {} if code.empty? || code.match?(/\A[^a-z0-9_-]+\z/)

    path = strings_dir.join("#{code}.yaml")
    return {} unless path.file?

    data = YAML.safe_load(File.read(path, encoding: "UTF-8"), permitted_classes: [Date, Time], aliases: true)
    return {} unless data.is_a?(Hash)

    data.each_with_object({}) { |(key, value), memo| memo[key.to_s] = value.to_s }
  rescue Psych::SyntaxError, SystemCallError
    {}
  end
end
