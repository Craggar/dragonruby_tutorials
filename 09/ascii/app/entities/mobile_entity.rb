module Entities
  class MobileEntity < Base
    include ::Behaviour::Occupant

    def self.spawn_near(state, spawn_x, spawn_y)
      radius = 1
      attempt = 0
      tile = state.map.tiles[spawn_x][spawn_y]
      while tile.nil? || tile.blocking?
        spawn_x = (spawn_x - radius..spawn_x + radius).to_a.sample
        spawn_y = (spawn_y - radius..spawn_y + radius).to_a.sample
        tile = state.map.tiles[spawn_x][spawn_y]
        attempt += 1
        next unless attempt >= radius * 8

        radius += 1
        attempt = 0
      end
      new(
        map_x: spawn_x * SPRITE_WIDTH,
        map_y: spawn_y * SPRITE_HEIGHT
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
