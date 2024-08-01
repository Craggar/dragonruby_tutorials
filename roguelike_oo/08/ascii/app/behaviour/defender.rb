module Behaviour
  module Defender
    attr_reader :hp, :defense

    def alive?
      hp > 0
    end

    def take_damage(damage)
      @hp = [
        0,
        hp - damage
      ].max
      puts "#{self.class} took #{damage} damage -> #{hp} remaining"
    end
  end
end
