require "test_helper"

# The reader of `manifest.toml`.
class ManifestReaderTest < ActiveSupport::TestCase
  test "reads the tables of a manifest" do
    data = ManifestReader.parse(<<~TOML)
      # A comment
      [project]
      name = "book-of-life"
      version = "0.1.0-alpha"

      [knowledge_base]
      default_language = "en"
      supported_languages = ["en", "es", "fr"]
    TOML

    assert_equal "book-of-life", data.dig("project", "name")
    assert_equal "0.1.0-alpha", data.dig("project", "version")
    assert_equal "en", data.dig("knowledge_base", "default_language")
    assert_equal %w[en es fr], data.dig("knowledge_base", "supported_languages")
  end

  test "reads a multi line array" do
    data = ManifestReader.parse(<<~TOML)
      [domains]
      list = [
        "survival",
        "water",
        "agriculture",
      ]
    TOML

    assert_equal %w[survival water agriculture], data.dig("domains", "list")
  end

  test "reads numbers and booleans" do
    data = ManifestReader.parse(<<~TOML)
      [build]
      strict = true
      size = 42
      ratio = 1.5
    TOML

    assert_equal true, data.dig("build", "strict")
    assert_equal 42, data.dig("build", "size")
    assert_in_delta 1.5, data.dig("build", "ratio")
  end

  test "reads the manifest of the repository" do
    data = ManifestReader.parse_file(Corpus.root.join("manifest.toml"))

    assert_equal "book-of-life", data.dig("project", "name")
    assert_equal 16, data.dig("domains", "list").size
    assert_equal %w[green yellow red], data.dig("safety", "levels")
  end
end
