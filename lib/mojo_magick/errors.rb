module MojoMagick
  class MojoMagickException < StandardError; end

  class MojoError < MojoMagickException; end

  class MojoFailed < MojoMagickException; end

  class SourceFileRequired < MojoError; end
end
