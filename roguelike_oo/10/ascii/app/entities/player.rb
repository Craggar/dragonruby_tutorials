module Entities
  class Player < MobileEntity
    include ::Behaviour::Defender
    include ::Behaviour::Attacker
    attr_reader :took_action, :took_damage

    def initialize(opts = {})
      super
      @path = 'app/sprites/player.png'
      @max_hp = 50
      @hp = max_hp
      @defense = 10
      @attack = 3
      @crit_bonus = 1
    end

    def faction
      'player'
    end

    def name
      'Player'
    end

    def tick(args)
      @took_action = false
      @took_damange = false
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
        args.state.redraw_entities = true
        args.state.redraw_play_area = true
        update_tile(args)
      end
    end

    def take_damage(damage)
      super
      @took_damage = true
    end

    def stats_labels
      [
        {x: 16, y: 700, text: hp_string}.merge(hp_string_color)
      ]
    end

    def hp_string
      hp_label = (hp < 10) ? "0#{hp}" : hp.to_s
      max_hp_label = (max_hp < 10) ? "0#{max_hp}" : max_hp.to_s
      "HP: #{hp_label} / #{max_hp_label}"
    end

    def hp_string_color
      if hp / max_hp >= 0.5
        {r: 10, g: 200, b: 10, a: 255}
      elsif hp / max_hp >= 0.2
        {r: 255, g: 165, b: 0, a: 255}
      else
        {r: 220, g: 0, b: 0, a: 255}
      end
    end
  end
end
