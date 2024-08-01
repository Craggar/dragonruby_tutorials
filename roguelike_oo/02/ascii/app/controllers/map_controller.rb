module Controllers
  class MapController
    MAP_WIDTH = 80
    MAP_HEIGHT = 45
    TILE_WIDTH = 32
    TILE_HEIGHT = 32

    def self.load_map(state)
      state.map.tiles = map_tiles
    end

    def self.map_tiles
      MAP_WIDTH.times.map do |tile_x|
        MAP_HEIGHT.times.map do |tile_y|
          if tile_y == 0 || tile_y == MAP_HEIGHT - 1 ||
            tile_x == 0 || tile_x == MAP_WIDTH - 1
            tile_for tile_x, tile_y, Entities::Wall
          else
            tile_for tile_x, tile_y, Entities::Floor
          end
        end
      end
    end

    def self.tile_for(tile_x, tile_y, tile_type)
      tile_type.new(
        x: tile_x * TILE_WIDTH,
        y: tile_y * TILE_HEIGHT,
        w: TILE_WIDTH,
        h: TILE_HEIGHT
      )
    end
  end
end
