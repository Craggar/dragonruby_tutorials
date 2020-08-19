module Controllers
  class GameController
    PLAY_AREA_WIDTH = 832
    PLAY_AREA_HEIGHT = 720
    TEXT_AREA_WIDTH = 1280 - PLAY_AREA_WIDTH
    TEXT_AREA_HEIGHT = 720

    def self.tick(args)
      args.state.player.tick(args)
      ::Controllers::EnemyController.tick(args)
    end

    def self.render(args, sprites, labels)
      render_play_area(args)
      render_text_area(args)
      sprites << [0, 0, PLAY_AREA_WIDTH, PLAY_AREA_HEIGHT, :play_area, 0, 255, 255, 255, 255, 0, 0, PLAY_AREA_WIDTH, PLAY_AREA_HEIGHT]
      sprites << [PLAY_AREA_WIDTH, 0, TEXT_AREA_WIDTH, TEXT_AREA_HEIGHT, :text_area, 0, 255, 255, 255, 255, 0, 0, TEXT_AREA_WIDTH, TEXT_AREA_HEIGHT]
    end

    def self.render_play_area(args)
      args.render_target(:play_area).sprites << args.state.map.tiles
      args.render_target(:play_area).sprites << args.state.enemies
      args.render_target(:play_area).sprites << args.state.player
    end

    def self.render_text_area(args)
      args.render_target(:text_area).solids << [0, 0, TEXT_AREA_WIDTH, TEXT_AREA_HEIGHT, 10, 21, 33]
      labels = []
      labels << args.state.player.stats_labels
      ::Controllers::EventLogsController.render(args, [], labels)
      args.render_target(:text_area).labels << labels
    end

    def self.reset(state)
      ::Controllers::EventLogsController.reset(state)
      ::Controllers::MapController.load_map(state)
      state.player = ::Entities::Player.spawn_near(state, 10, 11)
      ::Controllers::EnemyController.spawn_enemies(state)
    end
  end
end
