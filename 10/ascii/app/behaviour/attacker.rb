module Behaviour
  module Attacker
    attr_reader :attack, :crit

    def deal_damage(other)
      return unless other.respond_to?(:take_damage)

      roll = ::D20.roll(1)
      total_attack = if roll == 20
                       attack + crit
                     else
                       attack
                     end
      if roll >= other.defense
        other.take_damage(total_attack)
        ::Controllers::EventLogsController.log_event(
          "#{roll == 20 ? 'CRIT! ' : ''}#{self.class.name} hit #{other.class.name} for #{total_attack} damage"
        )
      else
        ::Controllers::EventLogsController.log_event(
          "#{self.class.name} missed #{other.class.name}!"
        )
      end
    end
  end
end
