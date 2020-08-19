## Introduction
This is the third part of a series of tutorials building a top-down 'Roguelike' game. In the previous installments we created a basic framework for our classes, controllers, entities, etc, and got some 'Static Entities' in the form of map tiles drawn on the screen.

I recommend you familiarise yourself with the previous parts, and we'll be using the 'final code' from the previous tutorial as our starting point here.

This tutorial will create our first motile entity - those that can move around - our Player.

## The Player
The simplest place to start is a player entity, but first lets set up our `MotileEntity` base class. Create a new file `/app/entities/motile_entity.rb`. Make sure to include this file within `main.rb` with:
```ruby
# /ascii/app/main.rb
require 'app/entities/motile_entity.rb'
```

This will, for now, be the same as our `Entities::StaticEntity` class, but serves as a place to hang any common behaviours or attributes that motile entities share. Put this code in the file:
```ruby
# /ascii/app/entities/motile_entity.rb
module Entities
  class MotileEntity < Base
  end
end
```
Next create `/app/entities/player.rb`, and fill in with this:
```ruby
# /ascii/app/entities/player.rb
module Entities
  class Player < MotileEntity
    def initialize(opts = {})
      super
      @path = 'app/sprites/player.png'
    end
  end
end
```
Just like with the `Wall` and `Floor` tiles, for now the only thing special about the player is that we load a player sprite (as ever, found in the example folder).

Then, of course, include it in `main.rb`:
```ruby
# /ascii/app/main.rb
require 'app/entities/player.rb'
```

To create a new player, we want a class-level (rather than instance level) spawn method. This is likely to be shared by most motile entities, so within `app/entities/motile_entity.rb` add a `spawn` method:
```ruby
# /ascii/app/entities/motile_entity.rb
def self.spawn(tile_x, tile_y)
  new(
    x: tile_x * SPRITE_WIDTH,
    y: tile_y * SPRITE_HEIGHT
  )
end
```

Let's check this in action. First, call the player `spawn` method from within the `GameController`'s reset method:
```ruby
# /ascii/app/controller/game_controller.rb
def self.reset(state)
  ::Controllers::MapController.load_map(state)
  state.player = ::Entities::Player.spawn(2, 2)
end
```
And make sure we are rendering the player sprite; again within the `GameController`, but this time in the `render` method:
```ruby
# /ascii/app/controller/game_controller.rb
def self.render(state, sprites, labels)
  sprites << state.map.tiles
  sprites << state.player
end
```
Run the game now, and you should see your player sprite showing near the bottom left corner. If you're not seeing anything, make sure you've copied the `player.png` from the examples folder into your `app/sprites` directory.

## Processing Inputs
Next up, we need to make the player move based on keyboard input - either cursor keys or WASD. Add a tick method to the `player.rb`:
```ruby
# /ascii/app/entities/player.rb
def tick(args)
  @y += ::Controllers::MapController::TILE_HEIGHT if args.inputs.keyboard.key_down.up || args.inputs.keyboard.key_down.w
  @y -= ::Controllers::MapController::TILE_HEIGHT if args.inputs.keyboard.key_down.down || args.inputs.keyboard.key_down.s
  @x += ::Controllers::MapController::TILE_WIDTH if args.inputs.keyboard.key_down.right || args.inputs.keyboard.key_down.d
  @x -= ::Controllers::MapController::TILE_WIDTH if args.inputs.keyboard.key_down.left || args.inputs.keyboard.key_down.a
end
```
This handles 4-directional movement via the up/down/left/right/WASD keys, moving the player by a single tile each time the key is pressed. This code isn't being called anywhere yet, so let's do so now. Within the `GameController`, replace the empty `tick` method with:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.tick(args)
  args.state.player.tick(args)
end
```

Run the game now, and you can move the player around the map with the keyboard. But if you play around you'll see that we can pass through walls and off the screen and so on. In the next tutorial, we'll map static entities either blocking or non-blocking, and we'll make the 'camera' follow the player.
