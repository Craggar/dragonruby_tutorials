require 'app/game.rb'

require 'app/controllers/title_controller.rb'
require 'app/controllers/game_controller.rb'

$game ||= Game.new
def tick(args)
  $game.tick(args)
end
