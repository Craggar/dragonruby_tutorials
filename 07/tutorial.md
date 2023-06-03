## Introduction

This is the seventh part of a series of tutorials building a top-down 'Roguelike' game. In the previous installments we created a basic framework for our classes, controllers, entities, etc, and got some 'Static Entities' in the form of map tiles drawn on the screen, and got our player entity rendered and moving around the screen, making the map/camera follow the player, and enabling tile-based collisions with the map. We also added our first enemies, and gave them a basic random movement/patrol behaviour and a 'seek player' behaviour, as well as introducing the concept of entities 'occupying' a tile, preventing other entities moving into them, to form our basic entity-to-entity collision.

I recommend you familiarise yourself with the previous parts, and we'll be using the 'final code' from the previous tutorial as our starting point here.

Next up we're going to take a bit of a break from extending our entities to lay out the screen using Render Targets.

## First Render Target

As it stands our game uses the entire screen to render the map, and the characters moving around on it, but ultimately we want to display other things on the screen. You might want to split the screen vertically like Caves of Qud, to have a 'map' area on the left and a 'stats/lore/log' area on the right. Or like ADOM have the map area taking up most of the upper few rows used for logging/text output of events, the lower few rows used for showing stats, with the remaining middle portion used for the map/play area.

I'm going to go for a left/right split, but first let's create our first in-game render target.

As it stands, our primary rendering `Controllers` (`GameController` and `TitleController`), expect `state` passed into their `render` methods. As we're about to start using render targets, we need the `args` in here. So in `Game` change the `active_controller.render...` call to:
```ruby
# /ascii/app/main.rb
active_controller.render(args, sprites, labels)
```
The `TitleController` doesn't do anything with the `state` that's passed, so updating is as simple as changing the method to:
```ruby
# /ascii/app/controllers/title_controller.rb
def self.render(args, sprites, labels)
  # ...etc
end
```
The `GameController` pushes sprites and labels onto the state, so it needs a _little_ more work, but still not a lot:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.render(args, sprites, labels)
  sprites << args.state.map.tiles
  sprites << args.state.enemies
  sprites << args.state.player
end
```

Now we're ready to refactor that render method to use a render target:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.render(args, sprites, labels)
  render_play_area(args)
  sprites << [0, 0, 1280, 720, :play_area]
end

def self.render_play_area(args)
  args.render_target(:play_area).sprites << args.state.map.tiles
  args.render_target(:play_area).sprites << args.state.enemies
  args.render_target(:play_area).sprites << args.state.player
end
```
Instead of moving the tiles/enemies/player sprites into `args.sprites`, we move them into a render target via `args.render_target(:play_area)`. That `render_target` is basically just a 'dynamic sprite' that we're creating on the fly, so in the last line we shift the `play_area` into the `sprites` array.

Run the code now, and you should see nothing different to how it was previously.

## Resize the Play Area
We want it to take up, say, about 2/3 of the screen, leaving the other 1/3 for the side-panel.

Within `GameController` add these two constants:
```ruby
# /ascii/app/controllers/game_controller.rb
PLAY_AREA_WIDTH = 832
PLAY_AREA_HEIGHT = 720
```
And change the rendering of the of the play area like this:
```ruby
# /ascii/app/controllers/game_controller.rb
sprites << [0, 0, PLAY_AREA_WIDTH, PLAY_AREA_HEIGHT, :play_area]
```
Hmmm. Looks a little squished, but it is at least taking up the correct amount of screen real estate.

To get things looking right, we need to dive into the extended (optional) parameters of a sprite. These are:
```ruby
[x, y, width, height, sprite_path, angle, alpha, red, green, blue, source_x, source_y, source_w, source_h, flip_vertically, flip_horizontally, angle_anchor_x, angle_anchor_y]
```
We need them up-to-and-including `source_h`, so we can set the `source_x`, `source_y`, `source_h` and `source_w`. We'll populate the `angle` with `0` and the `alpha`, `red`, `green`, `blue` to `255`:
```ruby
# /ascii/app/controllers/game_controller.rb
sprites << [0, 0, PLAY_AREA_WIDTH, PLAY_AREA_HEIGHT, :play_area, 0, 255, 255, 255, 255, 0, 0, PLAY_AREA_WIDTH, PLAY_AREA_HEIGHT]
```

This is looking a bit better, but we can walk off the screen, which is far from ideal. This is our map scrolling code, which is using the hard-coded values of 1280 and 720 for width/height of the screen.

In the MapController change the `max_x` and `max_y` as follows:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.max_x
  MAP_WIDTH * TILE_WIDTH - ::Controllers::GameController::PLAY_AREA_WIDTH
end

def self.max_y
  MAP_HEIGHT * TILE_HEIGHT - ::Controllers::GameController::PLAY_AREA_HEIGHT
end
```

And we need to replace the hard-coded 1280/720 values in the `MapController`'s `tick` method with these `PLAY_AREA_WIDTH` and `PLAY_AREA_HEIGHT` constants:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.tick(args)
  player = args.state.player
  map = args.state.map
  player_x_offset = player.map_x - map.x
  player_y_offset = player.map_y - map.y
  if player_x_offset < MOVEMENT_ZONE_BUFFER_X
    map.x = [min_x, map.x - TILE_WIDTH].max
  elsif player_x_offset > (::Controllers::GameController::PLAY_AREA_WIDTH - MOVEMENT_ZONE_BUFFER_X)
    map.x = [map.x + TILE_WIDTH, max_x].min
  end
  if player_y_offset < MOVEMENT_ZONE_BUFFER_Y
    map.y = [min_y, map.y - TILE_HEIGHT].max
  elsif player_y_offset > (::Controllers::GameController::PLAY_AREA_HEIGHT - MOVEMENT_ZONE_BUFFER_Y)
    map.y = [map.y + TILE_HEIGHT, max_y].min
  end

  args.state.map.tiles.flatten.each { |tile| tile.tick(args) }
end
```

## The Second Render Target
Let's cover the void area to the right with a beautiful blackish box, by adding another render target.

Set the size and width of this right column via two more constants in `GameController`:
```ruby
# /ascii/app/controllers/game_controller.rb
TEXT_AREA_WIDTH = 1280 - PLAY_AREA_WIDTH
TEXT_AREA_HEIGHT = 720
```
Add a new `render_text_area` method:
```ruby
def self.render_text_area(args)
  args.render_target(:text_area).solids << [0, 0, TEXT_AREA_WIDTH, TEXT_AREA_HEIGHT, 10, 21, 33]
end
```
> For `solids` we're setting x, y, width, height, r, g, b

And add a call to `render_text_area`, then shift it onto the `sprites` stack:
```ruby
def self.render(args, sprites, labels)
  render_play_area(args)
  render_text_area(args)
  sprites << [0, 0, PLAY_AREA_WIDTH, PLAY_AREA_HEIGHT, :play_area, 0, 255, 255, 255, 255, 0, 0, PLAY_AREA_WIDTH, PLAY_AREA_HEIGHT]
  sprites << [PLAY_AREA_WIDTH, 0, TEXT_AREA_WIDTH, TEXT_AREA_HEIGHT, :text_area, 0, 255, 255, 255, 255, 0, 0, TEXT_AREA_WIDTH, TEXT_AREA_HEIGHT]
end
```
