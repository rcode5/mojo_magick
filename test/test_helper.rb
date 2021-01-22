require "simplecov"
SimpleCov.start

require "minitest/autorun"
require File.expand_path(File.join(File.dirname(__FILE__), "..", "init"))
require "fileutils"
require "tempfile"
require "rspec/expectations"
