module MojoMagick
  class Font
    attr_accessor :name, :family, :style, :stretch, :weight, :glyphs

    def valid?
      !name.nil?
    end

    def initialize(property_hash = {})
      %i[name family style stretch weight glyphs].each do |f|
        setter = "#{f}="
        send(setter, property_hash[f])
      end
    end

    def self.all
      ImageMagick::Fonts.all
    end
  end
end
