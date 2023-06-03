require 'app/controllers/title_controller.rb'
require 'app/controllers/game_controller.rb'
require 'app/controllers/map_controller.rb'

require 'app/entities/base.rb'
require 'app/entities/static_entity.rb'
require 'app/entities/wall.rb'
require 'app/entities/floor.rb'
require 'app/entities/mobile_entity.rb'
require 'app/entities/player.rb'

class Game
  attr_reader :active_controller

  def goto_title
    @active_controller = ::Controllers::TitleController
  end

  def goto_game(args)
    ::Controllers::GameController.reset(args.state)
    @active_controller = ::Controllers::GameController
  end

  def tick(args)
    goto_title unless active_controller
    sprites = []
    labels = []
    active_controller.tick(args)
    active_controller.render(args.state, sprites, labels)
    render(args, sprites, labels)
  end

  def render(args, sprites, labels)
    args.outputs.sprites << sprites
    args.outputs.labels << labels
  end
end

$game ||= Game.new
def tick(args)
  $game.tick(args)
end
