# frozen_string_literal: true

require "yaml"
require "pathname"

# The knowledge base of *A Book Of Life To Rebuild The World*.
#
# The corpus is read-only content that lives on disk:
#
#   sidecars/<domain>/<slug>.pnk.yaml
#       the metadata of an entry: id, title, domain, tags, difficulty, safety,
#       time to complete, prerequisites, materials, tools, sources,
#       verification status and links;
#
#   domains/<domain>/<slug>.md
#       the Markdown body of an entry.
#
# This service reads both at boot and keeps them in memory. Nothing here
# touches the network and nothing here writes to the corpus.
class Corpus
  class RootNotFound < StandardError; end

  MANIFEST_FILENAME = "manifest.toml"
  SIDECARS_DIRNAME = "sidecars"
  DOMAINS_DIRNAME = "domains"
  SIDECAR_SUFFIX = ".pnk.yaml"
  DISCLAIMER_RELPATH = "docs/DISCLAIMER.md"
  DOMAIN_INDEX_RELPATH = "domains/README.md"
  STRINGS_DIRNAME = File.join("i18n", "strings")
  ROOT_ENV = "ABOOK_ROOT"

  # The fallback disclaimer, used when `docs/DISCLAIMER.md` cannot be read.
  DISCLAIMER_FALLBACK = <<~TEXT.freeze
    Reference and education only. Double-check everything against primary
    sources and qualified professionals. Never use one entry, or this
    project, as a sole source of information. Not professional advice of any
    kind. Red-level work needs training, supervision and the right
    equipment. Provided "as is", with no warranty, and with liability
    excluded as far as the law allows. Local law, standards and primary
    sources always win.
  TEXT

  class << self
    # Locate the root of the repository.
    #
    # The root is the directory that holds `manifest.toml`. It is found by
    # walking up from `Rails.root` (the `apps/web-rails` directory) until the
    # manifest turns up. `ABOOK_ROOT` overrides the search.
    #
    # @param start [String, Pathname, nil] where to start walking
    # @return [Pathname] the repository root
    # @raise [RootNotFound] when no manifest is found
    def root(start = nil)
      explicit = ENV[ROOT_ENV].to_s
      if !explicit.empty? && File.file?(File.join(explicit, MANIFEST_FILENAME))
        return Pathname.new(explicit).expand_path
      end

      base = Pathname.new((start || rails_root).to_s).expand_path
      base = base.dirname unless base.directory?

      base.ascend do |directory|
        return directory if directory.join(MANIFEST_FILENAME).file?
      end

      raise RootNotFound, "could not find #{MANIFEST_FILENAME} at or above #{base}"
    end

    # The corpus of this application, loaded once and kept in memory.
    #
    # The corpus is held in a class variable of `Corpus` itself, so that a
    # code reload in development rebuilds it from the files on disk.
    #
    # @return [Corpus] the loaded corpus
    def instance
      @instance ||= new(root: root)
    end

    # Forget the memoised corpus. Used by the tests.
    def reset!
      @instance = nil
    end

    private

    def rails_root
      defined?(Rails) && Rails.respond_to?(:root) && Rails.root ? Rails.root : Dir.pwd
    end
  end

  attr_reader :root, :manifest, :version, :default_language, :supported_languages,
              :safety_levels, :difficulty_levels, :entries, :domains, :warnings

  # @param root [String, Pathname, nil] the repository root
  def initialize(root: nil)
    @root = Pathname.new((root || self.class.root).to_s).expand_path
    @manifest = load_manifest
    @version = manifest_value("project", "version").to_s
    @default_language = manifest_value("knowledge_base", "default_language").to_s
    @default_language = "en" if @default_language.empty?
    @supported_languages = Array(manifest_value("knowledge_base", "supported_languages")).map(&:to_s)
    @safety_levels = Array(manifest_value("safety", "levels")).map(&:to_s)
    @difficulty_levels = Array(manifest_value("difficulty", "levels")).map(&:to_s)
    @warnings = []

    @entries = []
    @entries_by_id = {}
    @entries_by_key = {}
    @entries_by_domain = {}

    load_entries!
    build_domains!
  end

  # ------------------------------------------------------------------
  # Lookups
  # ------------------------------------------------------------------

  # The entry with the given identifier.
  #
  # @param id [String] for example `pnk:01HZX0K8J9Q7R3VY6T2M4B8N1P/survival/making-fire`
  # @return [Entry, nil] the entry, or nil when it is unknown
  def entry(id)
    @entries_by_id[id.to_s]
  end

  # The entry with the given "domain/slug" key.
  #
  # @param key [String] for example `survival/making-fire`
  # @return [Entry, nil] the entry, or nil when it is unknown
  def entry_by_key(key)
    @entries_by_key[key.to_s]
  end

  # The entry of a domain, addressed by its slug.
  #
  # @param domain [String] the domain slug
  # @param slug [String] the entry slug
  # @return [Entry, nil] the entry, or nil when it is unknown
  def entry_in(domain, slug)
    entry_by_key("#{domain}/#{slug}")
  end

  # The domain with the given slug.
  #
  # @param slug [String] the domain slug
  # @return [Domain, nil] the domain, or nil when it is unknown
  def domain(slug)
    domains_by_slug[slug.to_s]
  end

  # Every entry of a domain.
  #
  # @param slug [String] the domain slug
  # @return [Array<Entry>] the entries, empty when the domain is unknown
  def entries_for(slug)
    @entries_by_domain.fetch(slug.to_s, [])
  end

  def total_entries
    @entries.size
  end

  def domain_counts
    @domains.to_h { |item| [item.slug, item.count] }
  end

  def safety_counts
    @entries.group_by(&:safety).transform_values(&:size)
  end

  def difficulty_counts
    @entries.group_by(&:difficulty).transform_values(&:size)
  end

  # The entries an entry points at, split into related entries and
  # prerequisites. Identifiers that do not resolve are ignored.
  #
  # @param entry [Entry] the entry
  # @return [Hash{Symbol => Array<Entry>}] `:related` and `:prerequisites`
  def relations_for(entry)
    {
      related: entry.link_ids.filter_map { |id| self.entry(id) },
      prerequisites: entry.prerequisite_ids.filter_map { |id| self.entry(id) }
    }
  end

  # ------------------------------------------------------------------
  # Documents
  # ------------------------------------------------------------------

  # The directory that holds the interface string catalogues.
  #
  # @return [Pathname] the directory
  def strings_dir
    root.join(STRINGS_DIRNAME)
  end

  # The full text of `docs/DISCLAIMER.md`, quoted verbatim.
  #
  # @return [String] the disclaimer, or the built-in fallback
  def disclaimer
    @disclaimer ||= read_disclaimer
  end

  # The summary section (section 12) of `docs/DISCLAIMER.md`.
  #
  # @return [String] the summary, or the built-in fallback
  def disclaimer_summary
    @disclaimer_summary ||= extract_section(disclaimer, "12")
  end

  # The one line description of every domain, read from `domains/README.md`.
  #
  # @return [Hash{String => String}] the descriptions
  def domain_descriptions
    @domain_descriptions ||= read_domain_descriptions
  end

  private

  def domains_by_slug
    @domains_by_slug ||= @domains.to_h { |item| [item.slug, item] }
  end

  def load_manifest
    path = root.join(MANIFEST_FILENAME)
    return {} unless path.file?

    ManifestReader.parse_file(path)
  rescue StandardError => error
    @warnings << "#{MANIFEST_FILENAME}: #{error.message}"
    {}
  end

  def manifest_value(*keys)
    keys.reduce(@manifest) do |scope, key|
      scope.is_a?(Hash) ? scope[key] : nil
    end
  end

  def load_entries!
    sidecars = Dir.glob(root.join(SIDECARS_DIRNAME, "**", "*#{SIDECAR_SUFFIX}")).sort
    sidecars.each do |path|
      entry = build_entry(path)
      next if entry.nil?

      @entries << entry
      @entries_by_id[entry.id] = entry
      @entries_by_key[entry.key] = entry
    end

    @entries.sort_by! { |entry| [entry.domain, entry.title.downcase, entry.id] }
    @entries.each { |entry| (@entries_by_domain[entry.domain] ||= []) << entry }
  end

  def build_entry(path)
    meta = read_sidecar(path)
    return nil if meta.nil?

    relative = Pathname.new(path).relative_path_from(root.join(SIDECARS_DIRNAME))
    slug = relative.basename.to_s.delete_suffix(SIDECAR_SUFFIX)
    domain = meta["domain"].to_s
    domain = relative.dirname.to_s if domain.empty?

    body_path = root.join(DOMAINS_DIRNAME, relative.dirname, "#{slug}.md")
    body = body_path.file? ? File.read(body_path, encoding: "UTF-8") : ""

    Entry.new(
      id: meta["id"].to_s,
      title: meta["title"].to_s.empty? ? slug : meta["title"].to_s,
      domain: domain,
      slug: slug,
      path: body_path.relative_path_from(root).to_s,
      tags: to_string_list(meta["tags"]),
      difficulty: meta["difficulty"].to_s,
      safety: meta["safety"].to_s,
      time_to_complete: meta["time_to_complete"].to_s,
      prerequisites: to_string_list(meta["prerequisites"]),
      materials: to_string_list(meta["materials_required"]),
      tools: to_string_list(meta["tools_required"]),
      sources: build_sources(meta["sources"]),
      verification: build_verification(meta["verification"]),
      links: to_string_list(meta["links"]),
      body: body
    )
  end

  def read_sidecar(path)
    text = File.read(path, encoding: "UTF-8")
    meta = YAML.safe_load(text, permitted_classes: [Date, Time], aliases: true)
    unless meta.is_a?(Hash)
      @warnings << "#{path}: not a mapping"
      return nil
    end
    meta
  rescue Psych::SyntaxError => error
    @warnings << "#{path}: #{error.message}"
    nil
  rescue SystemCallError => error
    @warnings << "#{path}: #{error.message}"
    nil
  end

  def to_string_list(value)
    case value
    when nil then []
    when Array then value.map(&:to_s)
    when Hash then value.values.map(&:to_s)
    else [value.to_s]
    end
  end

  def build_sources(value)
    Array(value).map do |item|
      if item.is_a?(Hash)
        Source.new(title: item["title"].to_s, license: item["license"].to_s)
      else
        Source.new(title: item.to_s)
      end
    end
  end

  def build_verification(value)
    return Verification.new unless value.is_a?(Hash)

    Verification.new(
      status: value["status"].to_s,
      date: value["date"].to_s,
      reviewers: to_string_list(value["reviewers"]),
      tested_by: value["tested_by"].to_s,
      location: value["location"].to_s
    )
  end

  def build_domains!
    descriptions = domain_descriptions
    declared = Array(manifest_value("domains", "list")).map(&:to_s)
    found = @entries.map(&:domain).uniq

    @domains = (declared + (found - declared)).map do |slug|
      Domain.new(
        slug: slug,
        description: descriptions[slug].to_s,
        entries: @entries_by_domain.fetch(slug, [])
      )
    end
  end

  def read_disclaimer
    path = root.join(DISCLAIMER_RELPATH)
    return DISCLAIMER_FALLBACK unless path.file?

    text = File.read(path, encoding: "UTF-8")
    text.strip.empty? ? DISCLAIMER_FALLBACK : text
  rescue SystemCallError
    DISCLAIMER_FALLBACK
  end

  def read_domain_descriptions
    path = root.join(DOMAIN_INDEX_RELPATH)
    return {} unless path.file?

    descriptions = {}
    File.readlines(path, encoding: "UTF-8").each do |line|
      stripped = line.strip
      next unless stripped.start_with?("|")

      cells = stripped.strip("|").split("|").map(&:strip)
      next if cells.size < 2

      name = cells[0].sub(/\A\[([^\]]+)\].*\z/, '\1')
      next if name.empty? || name.start_with?("http")

      description = cells[1]
      next if description.empty? || description.chars.all? { |char| "-: ".include?(char) }

      descriptions[name] = description
    end
    descriptions
  rescue SystemCallError
    {}
  end

  # Extract the body of the `## <number>.` section of a Markdown document.
  def extract_section(text, number)
    collected = []
    inside = false

    text.to_s.each_line do |line|
      stripped = line.strip
      if stripped.start_with?("## ")
        break if inside

        inside = stripped.delete_prefix("## ").split(".").first.to_s.strip == number
        next
      end
      collected << line.rstrip if inside
    end

    collected.shift while collected.first&.strip.to_s.empty?
    collected.pop while collected.last&.strip.to_s.empty?
    collected.join("\n").strip
  end
end
