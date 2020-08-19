## Introduction

This is the fourth part of a series of tutorials building a top-down 'Roguelike' game. In the previous installments we created a basic framework for our classes, controllers, entities, etc, and got some 'Static Entities' in the form of map tiles drawn on the screen, and got our player entity rendered and moving around the screen, making the map/camera follow the player, and enabling tile-based collisions with the map. We also added our first enemies, and gave them a basic random movement/patrol behaviour

I recommend you familiarise yourself with the previous parts, and we'll be using the 'final code' from the previous tutorial as our starting point here.

Next up we're going to add more enemy behaviours (moving towards player when in range), and adding collisions between Entities.

## (Slightly) Smarter Enemies
Rather than just shuffling back and forth in random directions, enemies should seek the player when they get close enough. The first step to this is that entities need to know how far away another entity is. Time for some linear algebra. In `Entities::Base`, add this:
```ruby
# /ascii/app/entities/base.rb
def linear_distance_to(other)
  x_diff = other.map_x - map_x
  y_diff = other.map_y - map_y
  Math.sqrt((x_diff * x_diff) + (y_diff * y_diff))
end
```

Now, enemies need to leverage this information do decide whether to 'patrol' randomly, or whether to attack the player. Change the `Enemy`'s `tick` method to:
```ruby
# /ascii/app/entities/enemy.rb
def tick(args)
  act(args)
  @x = map_x - args.state.map.x
  @y = map_y - args.state.map.y
end
```
This `act` method is new. Populate it as:
```ruby
# /ascii/app/entities/enemy.rb
def act(args)
  if linear_distance_to(args.state.player) < VISIBLE_RANGE
    seek_player(args)
  else
    patrol(args)
  end
end
```
We need to add the `VISIBLE_RANGE` constant:
```ruby
# /ascii/app/entities/enemy.rb
VISIBLE_RANGE = 300
```
And both the 'movement' methods risk some code duplication. Extract some of the code from the `patrol` method into a new movement method:
```ruby
# /ascii/app/entities/enemy.rb
def patrol(args)
  direction = [:up, :down, :left, :right].sample
  move_towards(args, direction)
end

def move_towards(args, direction)
  target_x = map_x
  target_y = map_y
  case direction
  when :up
    target_y += ::Controllers::MapController::TILE_HEIGHT
  when :down
    target_y -= ::Controllers::MapController::TILE_HEIGHT
  when :left
    target_x -= ::Controllers::MapController::TILE_WIDTH
  when :right
    target_x += ::Controllers::MapController::TILE_WIDTH
  end
  attempt_move(args, target_x, target_y)
end
```
Now we have the `move_towards` method, the `seek_player` method becomes quite simple to implement:
```ruby
# /ascii/app/entities/enemy.rb
def seek_player(args)
  directions = []
  player = args.state.player
  directions << :left if player.map_x < map_x
  directions << :right if player.map_x > map_x
  directions << :up if player.map_y > map_y
  directions << :down if player.map_y < map_y
  direction = directions.sample
  move_towards(args, direction)
end
```
This method works out which directions of movement would close the gap on the player, then chooses from those directions at random (if there's more than one).
Run the code now, and you'll see the distant zombies shuffling around, but get to close and they will charge you.

## Entity-to-Entity collisions
There are loads of ways we could attempt collision between entities, and there are some that are better suited to different types of games - entities could have one or more hit boxes, which we combine with `intersects_rect?` to see if they overlap with any other entities hit boxes, which is great for things like platform games, or checking whether a projectile hits an entity in a bullet-hell game, and so on.

Because Roguelike's (I'm taking this in the traditional sense of "Being like the game 'Rogue'") tend to be grid-based, we can leverage the fact we already have a grid of tiles that can be blocking or non-blocking, by making a tile blocking, if it has an occupant that is also a 'blocking' entity.

So to start with, I'm going to treat our `Floor` object, going forward, as the prototypical "Tile that entities can walk on", and extend it to have an `occupant` field.
```ruby
# /ascii/app/entities/floor.rb
module Entities
  class Floor < StaticEntity
    attr_accessor :occupant
```
> We're using `attr_accessor` here because we want to be able to both 'get' and 'set' this value from an outside entity. We _could_ make this an `attr_reader`, but then we'd need a method like `def occupy(other)` to set the `@occupant` attribute.

Because `Floor` inherits from the base entity, it already has a `blocking?` method. We don't want to completely override that, but we _do_ want to extend it. Again within `Floor`, add this `blocking?` method:
```ruby
# /ascii/app/entities/floor.rb
def blocking?
  occupant&.blocking? || super
end
```
> There's some _ruby_ going on here. The `&.` is generally known as 'safe navigation' and means "try to access a method or attribute on this thing that might not exist", and lets that conditional fail early if there is no occupant on the tile, and revert to the `|| super` to call the parent `blocking?` method. This line is the equivalent of the perhaps more readable:
```ruby
  if occupant.nil?
    super
  else
    occupant.blocking?
  end
```

We also want to set moving entities to be blocking, so set this on the `MotileEntity`:
```ruby
# /ascii/app/entities/motile_entity.rb
def blocking?
  true
end
```

Finally, for this section, it makes sense that our Entities be broadly aware of what tile they're on. So within `Entities::Base` add this:
```ruby
# /ascii/app/entities/base.rb
def map_tile_x
  ::Controllers::MapController.map_x_to_tile_x(map_x)
end

def map_tile_y
  ::Controllers::MapController.map_x_to_tile_x(map_y)
end
```

## The first (of our) Mixins
There are behaviours that will be shared across classes that might not make sense existing at the base class, or might have to exist in multiple base classes. For example, we want entities to be able to occupy a tile, but the `Floor` tile itself is an `Entity`, so it doesn't make sense at `Entity::Base`.

So we're going to create a library that can be included into any Class so it can make use of the behaviours. Create a folder at `/app/behaviour`, and create a file in there called `occupant.rb`:
```ruby
# /ascii/app/behaviour/occupant.rb
module Behaviour
  module Occupant
    attr_reader :tile

    def update_tile(args)
      tile.occupant = nil if tile
      @tile = args.state.map.tiles[map_tile_x][map_tile_y]
      tile.occupant = self
    end
  end
end
```
All this adds is a readable attribute of `tile` (to any instance of a class that includes it), and adds an `update_tile` method, which clears the `occupant` attribute of the current tile, and sets the `occupant` tile of the new tile.

Remember to include this file in `main.rb`. Make sure you do so after the `Controllers`, and before any of the `Entities` that will be including this behaviour
```ruby
# /ascii/app/main.rb
require 'app/behaviour/occupant.rb'
```

Include this 'behaviour' into the `MotileEntity`:
```ruby
# /ascii/app/entities/motile_entity.rb
module Entities
  class MotileEntity < Base
    include ::Behaviour::Occupant
```

Now we need both our Player and our Enemies to update their occupied tile every time they move. Within the `Player`'s `tick` method, update the `attempt_move` block:
```ruby
# /ascii/app/entities/player.rb
attempt_move(args, target_x, target_y) do
  ::Controllers::MapController.tick(args)
  @took_action = true
  update_tile(args)
end
```
And within the `Enemy`'s `move_towards`, add a block to the `attempt_move` call:
```ruby
# /ascii/app/entities/enemy.rb
attempt_move(args, target_x, target_y) do
  update_tile(args)
end
```
