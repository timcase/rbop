# frozen_string_literal: true

require "simplecov"

SimpleCov.start do
  # Track only files in lib directory
  add_filter "/test/"
  add_filter "/spec/"
  add_filter "/bin/"
  add_filter do |src|
    # Only include files in our lib directory
    !src.filename.include?("/rbop/lib/")
  end

  # Track files in lib
  track_files "{lib}/**/*.rb"
  add_group "Libraries", "lib"
  minimum_coverage 28  # Coverage for current test suite
end

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rbop"

require "minitest/autorun"
require_relative "support/fake_runner"
