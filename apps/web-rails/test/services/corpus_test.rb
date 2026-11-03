require "test_helper"

# The corpus loader.
class CorpusTest < ActiveSupport::TestCase
  setup do
    @corpus = Corpus.new(root: Corpus.root)
  end

  test "finds the repository root by walking up from Rails.root" do
    root = Corpus.root

    assert root.join("manifest.toml").file?, "the manifest was not found above Rails.root"
    assert root.join("sidecars").directory?
    assert root.join("domains").directory?
    assert_operator root.to_s.length, :<, Rails.root.to_s.length
  end

  test "raises when there is no manifest above the starting point" do
    assert_raises(Corpus::RootNotFound) do
      Corpus.root(Dir.tmpdir)
    end
  end

  test "reads every sidecar and every body" do
    assert_operator @corpus.total_entries, :>, 0
    assert_equal @corpus.total_entries, @corpus.entries.map(&:id).uniq.size

    @corpus.entries.each do |entry|
      assert entry.id.start_with?("pnk:"), "#{entry.key} has no identifier"
      assert entry.title.present?, "#{entry.key} has no title"
      assert entry.domain.present?, "#{entry.key} has no domain"
      assert entry.body.present?, "#{entry.key} has no body"
    end

    assert_empty @corpus.warnings
  end

  test "knows the sixteen domains and how many entries they hold" do
    assert_equal 16, @corpus.domains.size
    assert_equal @corpus.total_entries, @corpus.domains.sum(&:count)
    assert_equal @corpus.total_entries, @corpus.domain_counts.values.sum

    @corpus.domains.each do |domain|
      assert domain.slug.present?
      assert domain.description.present?, "#{domain.slug} has no description"
      assert_operator domain.count, :>, 0
    end
  end

  test "finds an entry by its identifier and by its key" do
    entry = @corpus.entry_in("survival", "making-fire")

    assert_equal "Making Fire", entry.title
    assert_equal entry, @corpus.entry(entry.id)
    assert_equal entry, @corpus.entry_by_key("survival/making-fire")
    assert_nil @corpus.entry("pnk:does/not/exist")
    assert_nil @corpus.entry_by_key("survival/does-not-exist")
  end

  test "reads the metadata of an entry" do
    entry = @corpus.entry_in("survival", "making-fire")

    assert_equal "survival", entry.domain
    assert_equal "making-fire", entry.slug
    assert_equal "novice", entry.difficulty
    assert_equal "yellow", entry.safety
    assert_includes entry.tags, "fire"
    assert_equal "draft", entry.verification.status
    refute_empty entry.sources
    assert_equal "domains/survival/making-fire.md", entry.path
  end

  test "resolves the links and the prerequisites of an entry" do
    entry = @corpus.entry_in("survival", "search-and-rescue")
    relations = @corpus.relations_for(entry)

    assert_includes relations[:related].map(&:key), "survival/wildfire-evacuation"
    assert_includes relations[:prerequisites].map(&:key), "survival/basic-first-aid"
    assert_includes relations[:prerequisites].map(&:key), "survival/rope-cordage"
  end

  test "reads the version and the settings from the manifest" do
    assert_match(/\A\d+\.\d+\.\d+/, @corpus.version)
    assert_equal "en", @corpus.default_language
    assert_equal %w[green yellow red], @corpus.safety_levels
    assert_equal %w[novice apprentice journeyman master], @corpus.difficulty_levels
    assert_includes @corpus.supported_languages, "en"
  end

  test "quotes the disclaimer verbatim" do
    source = File.read(Corpus.root.join("docs/DISCLAIMER.md"), encoding: "UTF-8")

    assert_includes @corpus.disclaimer, source.strip
    assert_includes @corpus.disclaimer_summary, "Not professional advice of any kind."
    assert_includes @corpus.disclaimer_summary, "Local law, standards and primary sources always win."
  end

  test "reads the description of every domain" do
    assert_equal "Immediate needs: water, fire, shelter, first aid", @corpus.domain_descriptions["survival"]
    assert_equal @corpus.domain_descriptions["survival"], @corpus.domain("survival").description
  end

  test "counts the entries by safety level and by difficulty" do
    assert_equal @corpus.total_entries, @corpus.safety_counts.values.sum
    assert_equal @corpus.total_entries, @corpus.difficulty_counts.values.sum
  end
end
