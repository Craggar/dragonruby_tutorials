module Entities
  class Enemy < MobileEntity
    VISIBLE_RANGE = 300

    def tick(args)
      act(args)
      @x = map_x - args.state.map.x
      @y = map_y - args.state.map.y
    end

    def act(args)
      if linear_distance_to(args.state.player) < VISIBLE_RANGE
        seek_player(args)
      else
        patrol(args)
      end
    end

    def seek_player(args)
      directions = []
      player = args.state.player
      directions << :left if player.map_x < map_x
      directions << :right if player.map_x > map_x
      directions << :up if player.map_y > map_y
      directions << :down if player.map_y < map_y
      direction = directions.sample
      move_towards(args, direction)
    end

    def patrol(args)
      direction = [:up, :down, :left, :right].sample
      move_towards(args, direction)
    end

    def move_towards(args, direction)
      target_x = map_x
      target_y = map_y
      case direction
      when :up
        target_y += ::Controllers::MapController::TILE_HEIGHT
      when :down
        target_y -= ::Controllers::MapController::TILE_HEIGHT
      when :left
        target_x -= ::Controllers::MapController::TILE_WIDTH
      when :right
        target_x += ::Controllers::MapController::TILE_WIDTH
      end
      attempt_move(args, target_x, target_y) do
        update_tile(args)
      end
    end
  end
end
