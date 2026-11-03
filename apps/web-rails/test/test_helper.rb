ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors, with: :threads)

    # The knowledge base is read from disk. The tests build their own corpus
    # where they need to look at a specific state, so nothing has to be reset
    # between the tests.
  end
end
