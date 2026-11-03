# frozen_string_literal: true

# Ranking the corpus against a free-text query.
#
# The ranking is BM25 flavoured over three fields -- title, tags and body --
# weighted so that a title match always outranks a tag match, and a tag match
# always outranks a body match. On top of the token scoring there is a
# substring bonus, which is what makes "water pur" find *Water Purification*.
#
# The corpus has a few hundred entries, so an in-memory inverted index is both
# fast enough and easy to reason about.
class Search
  # Field weights. A title hit is worth eight tag hits, a tag hit is worth
  # three body hits.
  TITLE_WEIGHT = 8.0
  TAG_WEIGHT = 3.0
  BODY_WEIGHT = 1.0

  # BM25 parameters.
  K1 = 1.2
  B = 0.75

  # Bonus added when the whole query appears verbatim in a field.
  PHRASE_BONUS_TITLE = 60.0
  PHRASE_BONUS_TAGS = 20.0
  PHRASE_BONUS_BODY = 4.0

  # Weight of a token that only matches by prefix.
  PREFIX_WEIGHT = 0.35

  # How many vocabulary entries a prefix may expand into.
  MAX_PREFIX_EXPANSIONS = 12

  # Match tiers, highest first.
  TIER_TITLE = 3
  TIER_TAGS = 2
  TIER_BODY = 1

  # The maximum number of results a single query returns.
  MAX_RESULTS = 50

  # The maximum number of entries a listing without a query returns.
  BROWSE_LIMIT = 500

  # One ranked entry.
  class Result
    attr_reader :entry, :score, :tier, :snippet

    def initialize(entry:, score:, tier:, snippet: "")
      @entry = entry
      @score = score
      @tier = tier
      @snippet = snippet
    end

    # The name of the field that produced the match.
    #
    # @return [String] `title`, `tags` or `body`
    def matched_field
      case tier
      when TIER_TITLE then "title"
      when TIER_TAGS then "tags"
      else "body"
      end
    end
  end

  # Split a text into lowercase word tokens.
  #
  # Word characters exclude the underscore, so `first-aid` becomes two tokens
  # and non-latin scripts keep working.
  #
  # @param text [String] the text to split
  # @return [Array<String>] the tokens
  def self.tokenize(text)
    text.to_s.downcase.scan(/[[:alnum:]]+/)
  end

  attr_reader :corpus

  # The search index of a corpus, built once.
  #
  # The index is held in a class variable of `Search` itself, so that a code
  # reload in development rebuilds it, and so that it is built only once per
  # request in production.
  #
  # @param corpus [Corpus] the corpus to index
  # @return [Search] the search engine
  def self.for(corpus)
    @instance = nil if @instance && !@instance.corpus.equal?(corpus)
    @instance ||= new(corpus)
  end

  # @param corpus [Corpus] the corpus to index
  def initialize(corpus)
    @corpus = corpus
    @entries = corpus.entries
    build_index!
  end

  # Search the corpus.
  #
  # @param text [String] the free-text query
  # @param domain [String, nil] restrict the results to a single domain
  # @param safety [String, nil] restrict the results to a single safety level
  # @param difficulty [String, nil] restrict the results to a single difficulty
  # @param limit [Integer] the maximum number of results
  # @return [Array<Result>] the ranked results; title matches come first, then
  #   tag matches, then body matches. A blank query matches nothing.
  def query(text, domain: nil, safety: nil, difficulty: nil, limit: MAX_RESULTS)
    limit = limit.to_i
    limit = MAX_RESULTS if limit <= 0
    query_text = text.to_s.strip

    return [] if query_text.empty?

    terms = self.class.tokenize(query_text)
    return [] if terms.empty?

    scores = Hash.new(0.0)
    tiers = Hash.new(0)

    terms.each do |term|
      accumulate(scores, tiers, bm25(@postings[:title], @title_tokens, term, TITLE_WEIGHT), TIER_TITLE)
      accumulate(scores, tiers, bm25(@postings[:tags], @tag_tokens, term, TAG_WEIGHT), TIER_TAGS)
      accumulate(scores, tiers, bm25(@postings[:body], @body_tokens, term, BODY_WEIGHT), TIER_BODY)

      unless @postings[:title].key?(term)
        prefix_matches(term).each do |expansion|
          accumulate(scores, tiers, bm25(@postings[:title], @title_tokens, expansion, TITLE_WEIGHT * PREFIX_WEIGHT), TIER_TITLE)
        end
      end

      unless @postings[:tags].key?(term)
        prefix_matches(term).each do |expansion|
          accumulate(scores, tiers, bm25(@postings[:tags], @tag_tokens, expansion, TAG_WEIGHT * PREFIX_WEIGHT), TIER_TAGS)
        end
      end
    end

    apply_phrase_bonus(scores, tiers, query_text)

    results = tiers.filter_map do |position, tier|
      entry = @entries[position]
      next if entry.nil?
      next unless keep?(entry, domain, safety, difficulty)

      Result.new(entry: entry, score: scores[position], tier: tier, snippet: snippet_for(entry, terms))
    end

    results.sort_by! { |result| [-result.tier, -result.score, result.entry.title.downcase] }
    results.first(limit)
  end

  # The entries that match the filters, without a query.
  #
  # @param domain [String, nil] restrict the entries to a single domain
  # @param safety [String, nil] restrict the entries to a single safety level
  # @param difficulty [String, nil] restrict the entries to a single difficulty
  # @param limit [Integer] the maximum number of entries
  # @return [Array<Result>] the entries, by domain and then by title
  def browse(domain: nil, safety: nil, difficulty: nil, limit: BROWSE_LIMIT)
    limit = limit.to_i
    limit = BROWSE_LIMIT if limit <= 0

    @entries.select { |entry| keep?(entry, domain, safety, difficulty) }
            .sort_by { |entry| [entry.domain, entry.title.downcase] }
            .first(limit)
            .map { |entry| Result.new(entry: entry, score: 0.0, tier: TIER_BODY, snippet: entry.excerpt) }
  end

  # The entries that match a short quick-jump query.
  #
  # Titles that start with the query come first, then titles that contain it,
  # then entries whose slug or tags match.
  #
  # @param text [String] the query
  # @param limit [Integer] the maximum number of entries
  # @return [Array<Entry>] the matching entries, best match first
  def quick_jump(text, limit: 30)
    query_text = text.to_s.strip.downcase
    return @entries.first(limit) if query_text.empty?

    starts = []
    contains = []
    other = []

    @entries.each do |entry|
      title = entry.title.downcase
      if title.start_with?(query_text)
        starts << entry
      elsif title.include?(query_text)
        contains << entry
      elsif entry.slug.downcase.include?(query_text) || entry.tags.any? { |tag| tag.downcase.include?(query_text) }
        other << entry
      end
    end

    (starts + contains + other).first(limit)
  end

  private

  def build_index!
    @title_tokens = []
    @tag_tokens = []
    @body_tokens = []
    @title_lower = []
    @tags_lower = []
    @body_lower = []
    @postings = { title: {}, tags: {}, body: {} }

    @entries.each_with_index do |entry, position|
      title_tokens = self.class.tokenize(entry.title)
      tag_tokens = entry.tags.flat_map { |tag| self.class.tokenize(tag) }
      body_tokens = self.class.tokenize(entry.body)

      @title_tokens << title_tokens
      @tag_tokens << tag_tokens
      @body_tokens << body_tokens
      @title_lower << entry.title.downcase
      @tags_lower << entry.tags.join(" ").downcase
      @body_lower << entry.body.downcase

      add_postings(@postings[:title], position, title_tokens)
      add_postings(@postings[:tags], position, tag_tokens)
      add_postings(@postings[:body], position, body_tokens)
    end

    @vocabulary = (@postings[:title].keys | @postings[:tags].keys | @postings[:body].keys).sort
  end

  def add_postings(postings, position, tokens)
    counts = Hash.new(0)
    tokens.each { |token| counts[token] += 1 }
    counts.each { |token, count| postings[token] ||= []; postings[token] << [position, count] }
  end

  def accumulate(scores, tiers, field_scores, tier)
    field_scores.each do |position, value|
      scores[position] += value
      tiers[position] = tier if tiers[position] < tier
    end
  end

  def average_length(tokens)
    return 0.0 if tokens.empty?

    tokens.sum(&:size).to_f / tokens.size
  end

  def bm25(postings, lengths, term, weight)
    posting = postings[term]
    return {} if posting.nil? || posting.empty?

    total = @entries.size
    average = average_length(lengths)
    average = 1.0 if average.zero?
    document_frequency = posting.size
    idf = Math.log(1.0 + (total - document_frequency + 0.5) / (document_frequency + 0.5))
    scores = {}

    posting.each do |position, frequency|
      length = lengths[position].size
      length = 1 if length.zero?
      denominator = frequency + K1 * (1.0 - B + B * length / average)
      scores[position] = weight * idf * (frequency * (K1 + 1.0)) / denominator
    end

    scores
  end

  def prefix_matches(term)
    return [] if term.length < 2

    index = @vocabulary.bsearch_index { |candidate| candidate >= term }
    return [] if index.nil?

    matches = []
    while index < @vocabulary.size && matches.size < MAX_PREFIX_EXPANSIONS
      candidate = @vocabulary[index]
      break unless candidate.start_with?(term)

      matches << candidate
      index += 1
    end
    matches
  end

  def apply_phrase_bonus(scores, tiers, query_text)
    phrase = query_text.downcase.split(/\s+/).join(" ")
    return if phrase.length < 3

    @entries.each_with_index do |entry, position|
      if @title_lower[position].include?(phrase)
        scores[position] += PHRASE_BONUS_TITLE
        tiers[position] = TIER_TITLE
      elsif @tags_lower[position].include?(phrase)
        scores[position] += PHRASE_BONUS_TAGS
        tiers[position] = TIER_TAGS if tiers[position] < TIER_TAGS
      elsif @body_lower[position].include?(phrase)
        scores[position] += PHRASE_BONUS_BODY
        tiers[position] = TIER_BODY if tiers[position] < TIER_BODY
      end
    end
  end

  def keep?(entry, domain, safety, difficulty)
    return false if domain && !domain.to_s.empty? && entry.domain != domain.to_s
    return false if safety && !safety.to_s.empty? && entry.safety != safety.to_s
    return false if difficulty && !difficulty.to_s.empty? && entry.difficulty != difficulty.to_s

    true
  end

  def snippet_for(entry, terms)
    body = entry.body
    return "" if body.empty?

    lowered = body.downcase
    position = -1
    terms.each do |term|
      found = lowered.index(term)
      next if found.nil?

      position = found if position.negative? || found < position
    end
    position = 0 if position.negative?

    start = [position - 60, 0].max
    finish = [position + 140, body.length].min
    excerpt = Entry.plain_text(body[start...finish])
    excerpt = "…#{excerpt}" if start.positive?
    excerpt = "#{excerpt}…" if finish < body.length
    excerpt
  end
end
