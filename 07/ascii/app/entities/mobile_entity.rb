module Entities
  class MobileEntity < Base
    include ::Behaviour::Occupant

    def self.spawn(tile_x, tile_y)
      new(
        map_x: tile_x * SPRITE_WIDTH,
        map_y: tile_y * SPRITE_HEIGHT
      )
    end

    def attempt_move(args, target_x, target_y)
      tile_x = ::Controllers::MapController.map_x_to_tile_x(target_x)
      tile_y = ::Controllers::MapController.map_y_to_tile_y(target_y)
      return if ::Controllers::MapController.blocked?(args, tile_x, tile_y)

      @map_x = target_x
      @map_y = target_y
      yield if block_given?
      @x = map_x - args.state.map.x
      @y = map_y - args.state.map.y
    end

    def blocking?
      true
    end
  end
end
