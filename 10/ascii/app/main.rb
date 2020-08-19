require 'app/game.rb'
require 'app/controllers/title_controller.rb'
require 'app/controllers/game_controller.rb'
require 'app/controllers/map_controller.rb'
require 'app/controllers/enemy_controller.rb'
require 'app/controllers/event_logs_controller.rb'

require 'app/dice/dice.rb'
require 'app/dice/d20.rb'

require 'app/behaviour/occupant.rb'
require 'app/behaviour/defender.rb'
require 'app/behaviour/attacker.rb'

require 'app/entities/base.rb'
require 'app/entities/static_entity.rb'
require 'app/entities/wall.rb'
require 'app/entities/floor.rb'
require 'app/entities/mobile_entity.rb'
require 'app/entities/player.rb'
require 'app/entities/enemy.rb'
require 'app/entities/zombie.rb'

$game ||= Game.new
def tick(args)
  $game.tick(args)
end
