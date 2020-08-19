module Entities
  class Base
    attr_sprite

    SPRITE_WIDTH = 32
    SPRITE_HEIGHT = 32

    def initialize(opts = {})
      @x = opts[:x] || 0
      @y = opts[:y] || 0
      @w = opts[:w] || SPRITE_WIDTH
      @h = opts[:h] || SPRITE_HEIGHT
      @path = opts[:path] || 'app/sprites/null_sprite.png'
    end

    def serialize
      {
        x: x,
        y: y,
        w: w,
        h: h,
        path: path
      }
    end

    def inspect
      # Override the inspect method and return ~serialize.to_s~.
      serialize.to_s
    end

    def to_s
      #  Override to_s and return ~serialize.to_s~.
      serialize.to_s
    end
  end
end
