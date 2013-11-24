#!/usr/bin/env ruby
#

require 'mojo_magick'

MojoMagick::convert(nil, 'composite_out.png') do |c|
  c.size '200x200'
  c.delay 100
  c.image_block do # first layer
    c.background 'blue'
    c.fill 'white'
    c.gravity 'northwest'
    c.label 'NW'
  end
  c.image_block do # second layer
    c.background 'transparent'
    c.fill 'red'
    c.gravity 'southeast'
    c.label 'SE'
  end
  c.composite
end

