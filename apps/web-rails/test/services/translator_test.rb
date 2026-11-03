require "test_helper"
require "tmpdir"

# The interface strings and their fallback.
class TranslatorTest < ActiveSupport::TestCase
  setup do
    @strings_dir = Corpus.root.join("i18n", "strings")
  end

  test "offers every language of the repository" do
    translator = Translator.new(strings_dir: @strings_dir)
    expected = %w[en es fr de pt hi ar sw zh id it ja ko nl ru tr vi]

    assert_equal expected, translator.available_languages
    assert_equal expected, Translator::CANONICAL_LANGUAGES
  end

  test "translates a key into the active language" do
    translator = Translator.new(strings_dir: @strings_dir, language: "fr")

    assert_equal "fr", translator.language
    assert_equal "Domaines", translator.t("domains")
    assert_equal "Rechercher", translator.t("search")
    assert_equal "Un Livre De Vie Pour Reconstruire Le Monde", translator.t("site_name")
  end

  test "falls back to English for a key the language does not define" do
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, "en.yaml"), "greeting: \"Hello\"\nonly_english: \"English only\"\n")
      File.write(File.join(directory, "fr.yaml"), "greeting: \"Bonjour\"\n")

      translator = Translator.new(strings_dir: directory, language: "fr")

      assert_equal "Bonjour", translator.t("greeting")
      assert_equal "English only", translator.t("only_english")
    end
  end

  test "falls back to English for a language that has no catalogue" do
    translator = Translator.new(strings_dir: @strings_dir, language: "xx")

    assert_equal "en", translator.language
    assert_equal "Domains", translator.t("domains")
  end

  test "falls back to the built-in defaults when no catalogue can be read" do
    Dir.mktmpdir do |directory|
      translator = Translator.new(strings_dir: directory, language: "en")

      assert_equal "Domains", translator.t("domains")
    end
  end

  test "returns the key itself when nothing defines it" do
    translator = Translator.new(strings_dir: @strings_dir)

    assert_equal "no_such_key", translator.t("no_such_key")
  end

  test "interpolates the placeholders of a string" do
    translator = Translator.new(strings_dir: @strings_dir)

    assert_equal "207 entries", translator.t("entry_count", count: 207)
  end

  test "leaves a placeholder alone when it has no value" do
    translator = Translator.new(strings_dir: @strings_dir)

    assert_equal "{count} entries", translator.t("entry_count")
  end

  test "knows which languages are written from right to left" do
    translator = Translator.new(strings_dir: @strings_dir, language: "ar")

    assert_equal "ar", translator.language
    assert translator.right_to_left?
    refute translator.right_to_left?("en")
  end

  test "names every language in that language" do
    translator = Translator.new(strings_dir: @strings_dir)

    assert_equal "English", translator.language_name("en")
    assert_equal "العربية", translator.language_name("ar")
  end

  test "a broken catalogue does not stop the reader" do
    Dir.mktmpdir do |directory|
      File.write(File.join(directory, "en.yaml"), "greeting: \"Hello\"\n")
      File.write(File.join(directory, "de.yaml"), "greeting: \"[unclosed\n")

      translator = Translator.new(strings_dir: directory, language: "de")

      assert_equal "en", translator.language
      assert_equal "Hello", translator.t("greeting")
    end
  end
end
