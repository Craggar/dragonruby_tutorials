module Controllers
  class TitleController
    def self.tick(args)
      $game.goto_game(args) if args.inputs.keyboard.space
    end

    def self.render(state, sprites, labels)
      labels << [620, 300, 'ASCII']
      labels << [550, 100, 'Press space to start']
      sprites << [576, 500, 128, 101, 'dragonruby.png']
    end
  end
end
