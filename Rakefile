require 'rubygems'
require 'rake/testtask'

task default: 'test'
Rake::TestTask.new do |task|
  task.pattern = 'test/*_test.rb'
end

desc 'Build gem'
task :build do
  `rm mojo_magick-*.gem`
  puts `gem build mojo_magick.gemspec`
end
