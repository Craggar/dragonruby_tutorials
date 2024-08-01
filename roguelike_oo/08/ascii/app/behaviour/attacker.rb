module Behaviour
  module Attacker
    attr_reader :attack

    def deal_damage(other)
      return unless other.respond_to?(:take_damage)

      other.take_damage(attack)
    end
  end
end
