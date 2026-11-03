# frozen_string_literal: true

# The page of a single entry: its metadata, its body and the entries it points
# at.
class EntriesController < ApplicationController
  # One entry.
  def show
    @entry = corpus.entry_in(params[:domain], params[:slug])
    return render "errors/not_found", status: :not_found if @entry.nil?

    @relations = corpus.relations_for(@entry)
    remember_entry(@entry)
  end
end
