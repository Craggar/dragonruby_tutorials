module Entities
  class Player < MobileEntity
    include ::Behaviour::Attacker
    include ::Behaviour::Defender

    attr_reader :took_action

    def initialize(opts = {})
      super
      @path = 'app/sprites/player.png'
      @max_hp = 50
      @hp = max_hp
      @defense = 10
      @attack = 2
      @crit = 2
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

      move_or_attack(args, target_x, target_y) do
        ::Controllers::MapController.tick(args)
        @took_action = true
        update_tile(args)
      end
    end

    def faction
      'player'
    end

    def stats_labels
      [
        [16, 700, "#{hp_string}"].concat(hp_string_color)
      ]
    end

    def hp_string
      hp_label = hp < 10 ? "0#{hp}" : hp.to_s
      max_hp_label = max_hp < 10 ? "0#{max_hp}" : max_hp.to_s
      "HP: #{hp_label} / #{max_hp_label}"
    end

    def hp_string_color
      if hp / max_hp >= 0.5
        [10, 200, 10, 255]
      elsif hp / max_hp >= 0.2
        [255, 165, 0, 255]
      else
        [220, 0, 0, 255]
      end
    end

    def self.name
      'Player'
    end
  end
end
