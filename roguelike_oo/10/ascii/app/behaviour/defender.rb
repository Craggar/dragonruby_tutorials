module Behaviour
  module Defender
    attr_reader :max_hp, :hp, :defense

    def alive?
      hp > 0
    end

    def take_damage(damage)
      @hp = [
        0,
        hp - damage
      ].max
    end
  end
end
