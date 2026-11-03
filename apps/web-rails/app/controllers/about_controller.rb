# frozen_string_literal: true

# The about page: the version of the knowledge base and the disclaimer.
class AboutController < ApplicationController
  # The version, the counts and the disclaimer.
  def show
    @version = corpus.version
    @disclaimer = corpus.disclaimer
    @disclaimer_summary = corpus.disclaimer_summary
    @total_entries = corpus.total_entries
    @domain_count = corpus.domains.size
    @languages = available_languages
  end
end
