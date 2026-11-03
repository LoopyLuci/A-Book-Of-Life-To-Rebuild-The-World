require "test_helper"

# The search ranking.
class SearchTest < ActiveSupport::TestCase
  setup do
    @corpus = Corpus.new(root: Corpus.root)
    @search = Search.new(@corpus)
  end

  test "returns nothing for an empty query" do
    assert_empty @search.query("")
    assert_empty @search.query("   ")
    assert_empty @search.query("!!!")
  end

  test "ranks a title match first" do
    results = @search.query("making fire")

    assert results.any?
    assert_equal "survival/making-fire", results.first.entry.key
    assert_equal Search::TIER_TITLE, results.first.tier
    assert_equal "title", results.first.matched_field
  end

  test "groups the results by tier: title, then tags, then body" do
    results = @search.query("safety")
    tiers = results.map(&:tier)

    refute_empty tiers
    assert_equal tiers.sort.reverse, tiers
    assert_includes tiers, Search::TIER_TITLE
    assert_operator tiers.max, :<=, Search::TIER_TITLE
    assert_operator tiers.min, :>=, Search::TIER_BODY
  end

  test "returns at most fifty results" do
    assert_equal 50, Search::MAX_RESULTS
    assert_operator @search.query("water").size, :<=, Search::MAX_RESULTS
  end

  test "honours the limit" do
    assert_equal 3, @search.query("water", limit: 3).size
  end

  test "filters by domain" do
    results = @search.query("water", domain: "survival")

    refute_empty results
    assert results.all? { |result| result.entry.domain == "survival" }
  end

  test "filters by safety level" do
    results = @search.query("water", safety: "red")

    refute_empty results
    assert results.all? { |result| result.entry.safety == "red" }
  end

  test "filters by difficulty" do
    results = @search.query("water", difficulty: "novice")

    refute_empty results
    assert results.all? { |result| result.entry.difficulty == "novice" }
  end

  test "an empty query lists the entries that match the filters" do
    results = @search.browse(domain: "survival")

    refute_empty results
    assert results.all? { |result| result.entry.domain == "survival" }
    assert_equal @corpus.entries_for("survival").size, results.size
  end

  test "browsing without a filter lists the whole corpus" do
    assert_equal @corpus.total_entries, @search.browse.size
  end

  test "finds a phrase that appears in a title" do
    results = @search.query("water purification")

    assert_equal "survival/water-purification", results.first.entry.key
  end

  test "produces a snippet around the match" do
    result = @search.query("water").first

    refute_nil result
    assert result.snippet.present?
  end

  test "tokenizes hyphenated, underscored and non latin text" do
    assert_equal %w[first aid], Search.tokenize("First-Aid")
    assert_equal %w[water purification], Search.tokenize("water_purification")
    assert_equal %w[中文], Search.tokenize("中文")
    assert_equal %w[hello world], Search.tokenize("Hello, World!")
  end

  test "finds entries by slug and by tag with the quick jump" do
    results = @search.quick_jump("making")

    assert results.any?
    assert_equal "survival/making-fire", results.first.key
  end
end
