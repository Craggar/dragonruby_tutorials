module Controllers
  class MapController
    MAP_WIDTH = 80
    MAP_HEIGHT = 45
    TILE_WIDTH = 32
    TILE_HEIGHT = 32
    MOVEMENT_ZONE_BUFFER_X = 8 * TILE_WIDTH
    MOVEMENT_ZONE_BUFFER_Y = 6 * TILE_HEIGHT

    def self.tick(args)
      player = args.state.player
      map = args.state.map
      player_x_offset = player.map_x - map.x
      player_y_offset = player.map_y - map.y
      if player_x_offset < MOVEMENT_ZONE_BUFFER_X
        map.x = [min_x, map.x - TILE_WIDTH].max
      elsif player_x_offset > (::Controllers::GameController::PLAY_AREA_WIDTH - MOVEMENT_ZONE_BUFFER_X)
        map.x = [map.x + TILE_WIDTH, max_x].min
      end
      if player_y_offset < MOVEMENT_ZONE_BUFFER_Y
        map.y = [min_y, map.y - TILE_HEIGHT].max
      elsif player_y_offset > (::Controllers::GameController::PLAY_AREA_HEIGHT - MOVEMENT_ZONE_BUFFER_Y)
        map.y = [map.y + TILE_HEIGHT, max_y].min
      end

      args.state.map.tiles.flatten.each { |tile| tile.tick(args) }
    end

    def self.blocked?(args, tile_x, tile_y)
      tile = tile_at(args, tile_x, tile_y)
      return true unless tile

      tile.blocking?
    end

    def self.tile_at(args, tile_x, tile_y)
      return nil if tile_x < 0 || tile_x > MAP_WIDTH - 1
      return nil if tile_y < 0 || tile_y > MAP_HEIGHT - 1

      args.state.map.tiles[tile_x][tile_y]
    end

    def self.tile_occupant(args, tile_x, tile_y)
      tile = tile_at(args, tile_x, tile_y)
      return nil unless tile&.respond_to?(:occupant)

      tile.occupant
    end

    def self.map_x_to_tile_x(map_x)
      (map_x / TILE_WIDTH).floor
    end

    def self.map_y_to_tile_y(map_y)
      (map_y / TILE_HEIGHT).floor
    end

    def self.load_map(state)
      state.map.tiles = map_tiles
      state.map.x = 0
      state.map.y = 0
    end

    def self.map_tiles
      MAP_WIDTH.times.map do |tile_x|
        MAP_HEIGHT.times.map do |tile_y|
          if tile_y == 0 || tile_y == MAP_HEIGHT - 1 ||
            tile_x == 0 || tile_x == MAP_WIDTH - 1
            tile_for tile_x, tile_y, Entities::Wall
          else
            if (0..8).to_a.sample == 0
              tile_for tile_x, tile_y, Entities::Wall
            else
              tile_for tile_x, tile_y, Entities::Floor
            end
          end
        end
      end
    end

    def self.tile_for(tile_x, tile_y, tile_type)
      tile_type.new(
        map_x: tile_x * TILE_WIDTH,
        map_y: tile_y * TILE_HEIGHT,
        w: TILE_WIDTH,
        h: TILE_HEIGHT
      )
    end

    def self.min_x
      0
    end

    def self.min_y
      0
    end

    def self.max_x
      MAP_WIDTH * TILE_WIDTH - ::Controllers::GameController::PLAY_AREA_WIDTH
    end

    def self.max_y
      MAP_HEIGHT * TILE_HEIGHT - ::Controllers::GameController::PLAY_AREA_HEIGHT
    end
  end
end
