# frozen_string_literal: true

# The home page: the sixteen domains of the knowledge base with their entry
# counts, and the entries the reader read recently.
class HomeController < ApplicationController
  def index
    @domains = corpus.domains
    @total_entries = corpus.total_entries
    @version = corpus.version
  end
end
