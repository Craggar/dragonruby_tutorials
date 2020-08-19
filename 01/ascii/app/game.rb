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
