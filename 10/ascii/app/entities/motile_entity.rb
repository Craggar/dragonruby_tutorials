module Entities
  class MotileEntity < Base
    include ::Behaviour::Occupant

    def self.spawn(tile_x, tile_y)
      new(
        map_x: tile_x * SPRITE_WIDTH,
        map_y: tile_y * SPRITE_HEIGHT
      )
    end

    def move_or_attack(args, target_x, target_y)
      tile_x = ::Controllers::MapController.map_x_to_tile_x(target_x)
      tile_y = ::Controllers::MapController.map_y_to_tile_y(target_y)
      if ::Controllers::MapController.blocked?(args, tile_x, tile_y)
        other = ::Controllers::MapController.tile_occupant(args, tile_x, tile_y)
        if respond_to?(:deal_damage) && other && (other.faction != 'neutral' && other.faction != faction)
          deal_damage(other)
          yield
        end
      else
        @map_x = target_x
        @map_y = target_y
        yield if block_given?
      end
      @x = map_x - args.state.map.x
      @y = map_y - args.state.map.y
    end

    def blocking?
      true
    end
  end
end
