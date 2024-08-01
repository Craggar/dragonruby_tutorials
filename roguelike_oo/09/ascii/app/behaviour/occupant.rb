module Behaviour
  module Occupant
    attr_reader :tile

    def update_tile(args)
      tile.occupant = nil if tile
      @tile = args.state.map.tiles[map_tile_x][map_tile_y]
      tile.occupant = self
    end

    def free_tile_on_death(args)
      tile.occupant = nil
    end
  end
end
