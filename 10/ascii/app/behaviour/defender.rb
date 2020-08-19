module Behaviour
  module Defender
    attr_reader :max_hp, :hp, :defense

    def take_damage(damage)
      @hp = [
        0,
        hp - damage
      ].max
    end

    def alive?
      hp > 0
    end
  end
end
