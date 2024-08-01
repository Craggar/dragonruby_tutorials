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
      render_play_area(args) if args.state.redraw_play_area
      render_entities(args) if args.state.redraw_entities
      render_text_area(args) if args.state.redraw_text_area
      sprites << {x: 0, y: 0, w: PLAY_AREA_WIDTH, h: PLAY_AREA_HEIGHT, source_x: 0, source_y: 0, source_w: PLAY_AREA_WIDTH, source_h: PLAY_AREA_HEIGHT, path: :play_area}
      sprites << {x: 0, y: 0, w: PLAY_AREA_WIDTH, h: PLAY_AREA_HEIGHT, source_x: 0, source_y: 0, source_w: PLAY_AREA_WIDTH, source_h: PLAY_AREA_HEIGHT, path: :entities}
      sprites << {x: PLAY_AREA_WIDTH, y: 0, w: TEXT_AREA_WIDTH, h: TEXT_AREA_HEIGHT, source_x: 0, source_y: 0, source_w: TEXT_AREA_WIDTH, source_h: TEXT_AREA_HEIGHT, path: :text_area}
    end

    def self.render_play_area(args)
      args.state.redraw_play_area = false
      args.render_target(:play_area).sprites << args.state.map.tiles
    end

    def self.render_entities(args)
      args.state.redraw_entities = false
      args.render_target(:entities).sprites << args.state.enemies
      args.render_target(:entities).sprites << args.state.player
    end

    def self.render_text_area(args)
      args.state.redraw_text_area = false
      args.render_target(:text_area).solids << {x: 0, y: 0, w: TEXT_AREA_WIDTH, h: TEXT_AREA_HEIGHT, r: 10, g: 21, b: 33}
    end

    def self.reset(state)
      ::Controllers::MapController.load_map(state)
      state.player = ::Entities::Player.spawn_near(state, 10, 11)
      ::Controllers::EnemyController.spawn_enemies(state)
      state.redraw_play_area = true
      state.redraw_entities = true
      state.redraw_text_area = true
    end
  end
end
