module Behaviour
  module Attacker
    attr_reader :attack, :crit_bonus

    def deal_damage(other)
      return unless other.respond_to?(:take_damage)

      roll = ::D20.roll(1)
      puts "Rolled: #{roll == 20 ? 'CRIT!' : roll} against #{other.class}'s DEF: #{other.defense}"
      total_attack = if roll == 20
                      attack + crit_bonus
                    else
                      attack
                    end
      if roll >= other.defense
        other.take_damage(total_attack)
      else
        puts 'miss!'
      end
    end
  end
end
