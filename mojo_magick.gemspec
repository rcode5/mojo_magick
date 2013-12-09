$:.push File.expand_path("../lib", __FILE__)
require "mojo_magick/version"

post_install_message = <<EOF

Thanks for installing MojoMagick - keepin it simple!

*** To make this gem work, you need a few binaries!
Make sure you've got ImageMagick available.  http://imagemagick.org
If you plan to build images with text (using the "label" method) you'll need freetype and ghostscript as well.
Check out http://www.freetype.org and http://ghostscript.com respectively for installation info.

EOF

Gem::Specification.new do |s|
  s.name        = "mojo_magick"
  s.license  = 'MIT'
  s.version     = MojoMagick::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Steve Midgley", "Elliot Nelson", "Jon Rogers"]
  s.email       = ["science@misuse.org", "jon@rcode5.com"]
  s.homepage    = "http://github.com/rcode5/mojo_magick"
  s.summary     = "mojo_magick-#{MojoMagick::VERSION}"
  s.description = %q{Simple Ruby stateless module interface to imagemagick.}

  s.rubyforge_project = "mojo_magick"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_development_dependency('rake')
  s.add_development_dependency('simplecov')
  s.add_development_dependency('rspec-expectations')

  s.post_install_message = post_install_message
end
