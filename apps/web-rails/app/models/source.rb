# frozen_string_literal: true

# One cited source of an entry.
#
# The corpus records sources either as a bare string or as a mapping with a
# title and an optional licence, for example:
#
#   sources:
#     - title: USDA Beekeeping Handbook
#     - title: FAO Manual
#       license: CC-BY-SA-4.0
class Source
  attr_reader :title, :license

  def initialize(title: "", license: "")
    @title = title.to_s
    @license = license.to_s
  end

  def to_s
    license.empty? ? title : "#{title} (#{license})"
  end

  def ==(other)
    other.is_a?(Source) && other.title == title && other.license == license
  end
  alias eql? ==

  def hash
    [title, license].hash
  end
end
