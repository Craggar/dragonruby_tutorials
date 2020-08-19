require 'app/game.rb'
require 'app/controllers/title_controller.rb'
require 'app/controllers/game_controller.rb'
require 'app/controllers/map_controller.rb'

require 'app/entities/base.rb'
require 'app/entities/static_entity.rb'
require 'app/entities/wall.rb'
require 'app/entities/floor.rb'
require 'app/entities/mobile_entity.rb'
require 'app/entities/player.rb'

$game ||= Game.new
def tick(args)
  $game.tick(args)
end
