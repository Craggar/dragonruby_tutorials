module Entities
  class Player < MotileEntity
    def initialize(opts = {})
      super
      @path = 'app/sprites/player.png'
    end

    def tick(args)
      @y += ::Controllers::MapController::TILE_HEIGHT if args.inputs.keyboard.key_down.up || args.inputs.keyboard.key_down.w
      @y -= ::Controllers::MapController::TILE_HEIGHT if args.inputs.keyboard.key_down.down || args.inputs.keyboard.key_down.s
      @x += ::Controllers::MapController::TILE_WIDTH if args.inputs.keyboard.key_down.right || args.inputs.keyboard.key_down.d
      @x -= ::Controllers::MapController::TILE_WIDTH if args.inputs.keyboard.key_down.left || args.inputs.keyboard.key_down.a
    end
  end
end
