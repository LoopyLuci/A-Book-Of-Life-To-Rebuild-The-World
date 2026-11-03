# frozen_string_literal: true

# One knowledge base entry: the metadata of a sidecar plus its Markdown body.
#
# Entries are read-only value objects. Nothing in the application writes to
# the corpus, and no entry is persisted in a database.
class Entry
  # A prerequisite or link that points at another entry.
  ID_PREFIX = "pnk:"

  attr_reader :id, :title, :domain, :slug, :path, :tags, :difficulty, :safety,
              :time_to_complete, :prerequisites, :materials, :tools, :sources,
              :verification, :links, :body

  def initialize(id:, title:, domain:, slug:, path: "", tags: [], difficulty: "",
                 safety: "", time_to_complete: "", prerequisites: [], materials: [],
                 tools: [], sources: [], verification: nil, links: [], body: "")
    @id = id.to_s
    @title = title.to_s
    @domain = domain.to_s
    @slug = slug.to_s
    @path = path.to_s
    @tags = Array(tags).map(&:to_s)
    @difficulty = difficulty.to_s
    @safety = safety.to_s
    @time_to_complete = time_to_complete.to_s
    @prerequisites = Array(prerequisites).map(&:to_s)
    @materials = Array(materials).map(&:to_s)
    @tools = Array(tools).map(&:to_s)
    @sources = Array(sources)
    @verification = verification || Verification.new
    @links = Array(links).map(&:to_s)
    @body = body.to_s
  end

  # The stable "domain/slug" key of the entry, used for cookies and lookups.
  def key
    "#{domain}/#{slug}"
  end

  def to_param
    slug
  end

  # The identifiers of the entries this entry points at.
  def prerequisite_ids
    prerequisites.select { |value| value.start_with?(ID_PREFIX) }
  end

  # The prerequisites that are plain text rather than a link to another entry.
  def free_prerequisites
    prerequisites.reject { |value| value.start_with?(ID_PREFIX) }
  end

  def link_ids
    links.select { |value| value.start_with?(ID_PREFIX) }
  end

  # The catalogue key that holds the human readable label of the safety level.
  def safety_label_key
    "safety_#{safety}"
  end

  # The catalogue key that holds the human readable label of the difficulty.
  def difficulty_label_key
    "difficulty_#{difficulty}"
  end

  # A short plain text excerpt of the body, used for meta descriptions and
  # for the fallback snippet of a search result.
  #
  # @param length [Integer] the maximum number of characters
  # @return [String] the excerpt
  def excerpt(length = 220)
    text = self.class.plain_text(body)
    return text if text.length <= length

    "#{text[0, length].rstrip}…"
  end

  # The plain text of a Markdown document, without any markup.
  #
  # @param text [String] the Markdown source
  # @return [String] the plain text
  def self.plain_text(text)
    text.to_s
        .gsub(/```.*?```/m, " ")
        .gsub(/`([^`]*)`/, '\1')
        .gsub(/!\[[^\]]*\]\([^)]*\)/, " ")
        .gsub(/\[([^\]]*)\]\([^)]*\)/, '\1')
        .gsub(/^[ \t]{0,3}#{'#'}[ \t]*/, "")
        .gsub(/^[ \t]{0,3}>[ \t]?/, "")
        .gsub(/^[ \t]{0,3}[-*+][ \t]+/, "")
        .gsub(/^[ \t]{0,3}\d{1,9}[.)][ \t]+/, "")
        .gsub(/^[ \t]{0,3}\|/, "")
        .gsub(/[*_~|]/, "")
        .gsub(/\s+/, " ")
        .strip
  end

  def search_text
    ([title, tags.join(" "), body]).join("\n")
  end

  def ==(other)
    other.is_a?(Entry) && other.id == id && other.key == key
  end
  alias eql? ==

  def hash
    [id, key].hash
  end
end
