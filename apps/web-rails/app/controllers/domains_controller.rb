# frozen_string_literal: true

# The domain index and the page of a single domain.
class DomainsController < ApplicationController
  # The list of every domain.
  def index
    @domains = corpus.domains
  end

  # One domain and the entries it holds.
  def show
    @domain = corpus.domain(params[:slug])
    return render "errors/not_found", status: :not_found if @domain.nil?

    @entries = @domain.entries
  end
end
