# Be sure to restart your server when you modify this file.
#
# The knowledge base is read-only content that lives on disk. It is read once
# at boot and kept in memory, so that serving a page never touches the disk
# and the application works completely offline.
#
# The corpus and the search index live in the application store rather than in
# a constant, so that they survive a code reload in development.

Rails.application.config.to_prepare do
  corpus = Corpus.instance

  # The interface languages are the languages that have a catalogue in
  # `i18n/strings/`. They are registered with I18n so that Rails accepts them
  # as the locale of a request.
  translator = Translator.new(strings_dir: corpus.strings_dir)
  I18n.available_locales = translator.available_languages.map(&:to_sym)
  I18n.default_locale = :en
end
