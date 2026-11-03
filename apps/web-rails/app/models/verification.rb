# frozen_string_literal: true

# The verification state of an entry.
#
# The lifecycle documented in `manifest.toml` is
# `draft` -> `peer-reviewed` -> `field-tested` -> `deprecated`.
class Verification
  STATUSES = %w[draft peer-reviewed field-tested deprecated].freeze

  attr_reader :status, :date, :reviewers, :tested_by, :location

  def initialize(status: "draft", date: "", reviewers: [], tested_by: "", location: "")
    @status = status.to_s.presence || "draft"
    @date = date.to_s
    @reviewers = Array(reviewers).map(&:to_s)
    @tested_by = tested_by.to_s
    @location = location.to_s
  end

  # The catalogue key that holds the human readable label of the status,
  # for example `status_field_tested`.
  def label_key
    "status_#{status.tr("-", "_")}"
  end

  def known?
    STATUSES.include?(status)
  end

  def to_s
    status
  end

  def ==(other)
    other.is_a?(Verification) && other.status == status && other.date == date &&
      other.reviewers == reviewers && other.tested_by == tested_by && other.location == location
  end
  alias eql? ==

  def hash
    [status, date, reviewers, tested_by, location].hash
  end
end
