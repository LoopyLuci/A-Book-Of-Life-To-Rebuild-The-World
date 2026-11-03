ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../Gemfile", __dir__)

require "bundler/setup" # Set up gems listed in the Gemfile.

# Bootsnap is not loaded on purpose: the app starts fast without it, and its
# native extension does not build or load on every Ruby. See the Gemfile.
