module Controllers
  class GameController
    def self.tick(args)
    end

    def self.render(state, sprites, labels)
      sprites << state.map.tiles
    end

    def self.reset(state)
      ::Controllers::MapController.load_map(state)
    end
  end
end
