module Controllers
  class EnemyController
    def self.tick(args)
      return unless args.state.player.took_action
      enemies = args.state.enemies
      enemies.each { |enemy| enemy.tick(args) }
    end

    def self.spawn_enemies(state)
      state.enemies ||= []
      30.times do
        tile_x = (::Controllers::MapController::MAP_WIDTH * rand).floor
        tile_y = (::Controllers::MapController::MAP_HEIGHT * rand).floor
        spawn_enemy(
          state,
          tile_x,
          tile_y,
          ::Entities::Zombie
        )
      end
    end

    def self.spawn_enemy(state, tile_x, tile_y, enemy_type)
      state.enemies << enemy_type.spawn(
        tile_x,
        tile_y
      )
    end
  end
end
