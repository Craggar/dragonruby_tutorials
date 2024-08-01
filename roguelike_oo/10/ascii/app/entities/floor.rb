module Entities
  class Floor < StaticEntity
    attr_accessor :occupant

    def initialize(opts = {})
      super
      @path = 'app/sprites/floor.png'
    end

    def blocking?
      occupant&.blocking? || super
    end
  end
end
