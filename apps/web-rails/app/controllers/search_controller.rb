# frozen_string_literal: true

# The search page: a free text query with filters for the domain, the safety
# level and the difficulty of an entry.
class SearchController < ApplicationController
  # The ranked results.
  def index
    @query = params[:q].to_s.strip
    @domain = filter_value(params[:domain])
    @safety = filter_value(params[:safety])
    @difficulty = filter_value(params[:difficulty])

    @results = if @query.present?
                 search_engine.query(
                   @query,
                   domain: @domain,
                   safety: @safety,
                   difficulty: @difficulty,
                   limit: Search::MAX_RESULTS
                 )
               else
                 search_engine.browse(
                   domain: @domain,
                   safety: @safety,
                   difficulty: @difficulty,
                   limit: Search::BROWSE_LIMIT
                 )
               end
    @result_count = @results.size
  end

  private

  def filter_value(value)
    text = value.to_s.strip
    text.empty? ? nil : text
  end
end
