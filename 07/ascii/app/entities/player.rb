module Entities
  class Player < MotileEntity
    attr_reader :took_action

    def initialize(opts = {})
      super
      @path = 'app/sprites/player.png'
    end

    def tick(args)
      @took_action = false
      target_x = if args.inputs.keyboard.key_down.right || args.inputs.keyboard.key_down.d
                   map_x + ::Controllers::MapController::TILE_WIDTH
                 elsif args.inputs.keyboard.key_down.left || args.inputs.keyboard.key_down.a
                   map_x - ::Controllers::MapController::TILE_WIDTH
                 else
                   map_x
                 end
      target_y = if args.inputs.keyboard.key_down.up || args.inputs.keyboard.key_down.w
                   map_y + ::Controllers::MapController::TILE_HEIGHT
                 elsif args.inputs.keyboard.key_down.down || args.inputs.keyboard.key_down.s
                   map_y - ::Controllers::MapController::TILE_HEIGHT
                 else
                   map_y
                 end
      return unless target_x != map_x || target_y != map_y

      attempt_move(args, target_x, target_y) do
        ::Controllers::MapController.tick(args)
        @took_action = true
        update_tile(args)
      end
    end
  end
end
