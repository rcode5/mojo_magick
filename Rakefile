require "rubygems"
require "simplecov"
require "rake/testtask"

task default: [:test]

Rake::TestTask.new do |t|
  t.libs = ["minitest"]
  t.test_files = Dir.glob(File.join(File.dirname(__FILE__), "test/*_test.rb"))
  t.verbose = true
end

desc "Build gem"
task :build do
  `rm mojo_magick-*.gem`
  puts `gem build mojo_magick.gemspec`
end

desc "Release"
task release: :build do
  puts `gem push mojo_magick-*.gem`
end
