require 'rubygems'

task 'default' => :test

desc "Default: run tests"
task :test do
  require 'simplecov'
  SimpleCov.start
  require 'rake/runtest'
  files = Dir.glob(File.join(File.dirname(__FILE__), 'test/*_test.rb'))
  files.each do |f|
    Rake.run_tests f
  end
end

desc "Build gem"
task :build do
  `rm mojo_magick-*.gem`
  puts `gem build mojo_magick.gemspec`  
end
