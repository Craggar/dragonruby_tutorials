module Entities
  class Zombie < Enemy
    def initialize(opts = {})
      super
      @path = 'app/sprites/zombie.png'
      @defense = 4
    end

    def name
      'Zombie'
    end
  end
end
