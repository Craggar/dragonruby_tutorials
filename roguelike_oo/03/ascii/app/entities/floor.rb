module Entities
  class Floor < StaticEntity
    def initialize(opts = {})
      super
      @path = 'app/sprites/floor.png'
    end
  end
end
