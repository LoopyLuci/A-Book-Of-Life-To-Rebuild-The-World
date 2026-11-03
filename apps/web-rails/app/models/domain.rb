# frozen_string_literal: true

# One of the sixteen domains of the knowledge base.
#
# A domain groups the entries that live in `domains/<domain>/` and
# `sidecars/<domain>/`.
class Domain
  attr_reader :slug, :title, :description, :entries

  def initialize(slug:, title: nil, description: nil, entries: [])
    @slug = slug.to_s
    @title = (title || default_title).to_s
    @description = description.to_s
    @entries = Array(entries)
  end

  def count
    entries.size
  end
  alias entry_count count

  def to_param
    slug
  end

  def persisted?
    true
  end

  def ==(other)
    other.is_a?(Domain) && other.slug == slug
  end
  alias eql? ==

  def hash
    slug.hash
  end

  private

  def default_title
    slug.split(/[-_]/).map { |part| part.capitalize }.join(" ")
  end
end
