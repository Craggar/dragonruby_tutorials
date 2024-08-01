module Controllers
  class GameController
    def self.tick(args)
      args.state.player.tick(args)
      ::Controllers::EnemyController.tick(args)
    end

    def self.render(state, sprites, labels)
      sprites << state.map.tiles
      sprites << state.enemies
      sprites << state.player
    end

    def self.reset(state)
      ::Controllers::MapController.load_map(state)
      state.player = ::Entities::Player.spawn_near(state, 10, 11)
      ::Controllers::EnemyController.spawn_enemies(state)
    end
  end
end
