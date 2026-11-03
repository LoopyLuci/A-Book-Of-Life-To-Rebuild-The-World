# frozen_string_literal: true

# The base controller of the application.
#
# It sets the language of the request, exposes the corpus to the views and
# keeps the reader's preferences -- the theme and the recently read entries --
# in cookies.
class ApplicationController < ActionController::Base
  # The number of entries the recently read list keeps.
  RECENT_LIMIT = 12

  # How long a preference cookie lives.
  PREFERENCE_TTL = 365.days

  before_action :set_locale
  before_action :set_theme

  helper_method :corpus, :translator, :current_locale, :rtl?, :theme,
                :recently_read_entries, :available_languages

  private

  # The corpus of the knowledge base.
  #
  # @return [Corpus] the loaded corpus
  def corpus
    @corpus ||= Corpus.instance
  end

  # The search index over the corpus.
  #
  # @return [Search] the search engine
  def search_engine
    @search_engine ||= Search.for(corpus)
  end

  # The interface strings of the active language.
  #
  # @return [Translator] the translator
  def translator
    @translator ||= Translator.new(strings_dir: corpus.strings_dir, language: corpus.default_language)
  end

  # The language of the request.
  #
  # The language comes from the `lang` parameter, then from the cookie the
  # language switcher writes, then from the default language of the manifest.
  #
  # @return [String] the language code
  def current_locale
    @current_locale ||= translator.language
  end

  # Whether the active language is written from right to left.
  #
  # @return [Boolean] true for right to left languages
  def rtl?
    translator.right_to_left?(current_locale)
  end

  # The languages the reader can switch to.
  #
  # @return [Array<String>] the language codes
  def available_languages
    translator.available_languages
  end

  # The theme the reader asked for, or nil when the system preference is used.
  #
  # @return [String, nil] `light`, `dark` or nil
  def theme
    @theme
  end

  # The entries the reader read recently, most recent first.
  #
  # @return [Array<Entry>] the entries
  def recently_read_entries
    @recently_read_entries ||= recent_keys.filter_map { |key| corpus.entry_by_key(key) }
  end

  # Remember that an entry was read.
  #
  # @param entry [Entry] the entry
  def remember_entry(entry)
    keys = recent_keys - [entry.key]
    keys.unshift(entry.key)
    cookies[:abook_recent] = {
      value: keys.first(RECENT_LIMIT).join(","),
      expires: PREFERENCE_TTL.from_now,
      same_site: :lax,
      httponly: true
    }
  end

  # The keys of the recently read entries, in the order they were read.
  #
  # @return [Array<String>] the "domain/slug" keys
  def recent_keys
    cookies[:abook_recent].to_s.split(",").map(&:strip).reject(&:empty?).first(RECENT_LIMIT)
  end

  # Set the language of the request.
  #
  # The language comes from the `lang` parameter, then from the cookie the
  # language switcher writes, then from the default language of the manifest.
  # An unknown language falls back to English.
  def set_locale
    requested = params[:lang].presence || cookies[:abook_lang].presence || corpus.default_language
    translator.set_language(requested)
    @current_locale = translator.language
    I18n.locale = @current_locale.to_sym
  end

  # Read the theme the reader asked for.
  #
  # Without a cookie the reader follows the preference of the operating
  # system.
  def set_theme
    value = cookies[:abook_theme].to_s
    @theme = %w[light dark].include?(value) ? value : nil
  end
end
