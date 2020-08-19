## Introduction

This is the fourth part of a series of tutorials building a top-down 'Roguelike' game. In the previous installments we created a basic framework for our classes, controllers, entities, etc, and got some 'Static Entities' in the form of map tiles drawn on the screen, and got our player entity rendered and moving around the screen.

I recommend you familiarise yourself with the previous parts, and we'll be using the 'final code' from the previous tutorial as our starting point here.

Next up we're going to move the 'camera' around to track the player. We'll be doing this by offsetting the 'origin' of the Map relative to the screen as the player moves. It's important that we start tracking the position of all of our entities relative to the map position, and that we translate the entity's relative map position into a screen position. This requires handling their coordinates differently, but will ultimately enable a scrolling map.

The Player is (for now at least) the only entity that we want to be able to move the camera around. We will make the camera move by setting a 'border' number of tiles that will move the camera to keep the player 'in frame' if the player moves into them.

## The 'new' X/Y (map_x/map_y)

First we need to track the x/y of the map _relative_ to the bottom-left corner of the screen. The maximum this can be is `0, 0` (as if we go into negative offset the map will move up & right on the screen and we'll start showing spaces where there are no tiles to show), and the maximum coordinates are
```
((MAP_WIDTH * TILE_WIDTH) - SCREEN_WIDTH
```
and
```
(MAP_HEIGHT * TILE_HEIGHT) - SCREEN_HEIGHT)
```

Let's add those as helper methods on the MapController:
```ruby
# /ascii/app/controllers/map_controller/rb
def self.min_x
  0
end

def self.min_y
  0
end

def self.max_x
  MAP_WIDTH * TILE_WIDTH - 1280
end

def self.max_y
  MAP_HEIGHT * TILE_HEIGHT - 720
end
```

We want to track the `map_x` and `map_y` of all entities. Currently they track `x` and `y`, but this is their position on screen (because that's what the `attr_sprite` mixin gave us), what we want to track is the global position, relative to the origin (`0,0`) of the map, then convert that into a screen position for render.

Modify `entities/base.rb` to add a couple of attributes directly below `attr_sprite`:
```ruby
# /ascii/app/entities/base.rb
attr_reader :map_x, :map_y
```
Then in the `initialize` method, change the part where we assign x/y from the options, to instead assign `map_x` and `map_y`, and copy those values to screen `x`/`y`:
```ruby
# /ascii/app/entities/base.rb
def initialize(opts = {})
  @map_x = opts[:map_x] || 0
  @map_y = opts[:map_y] || 0
  @x = map_x
  @y = map_y
  # ...etc
end
```
Change the `MapController#tile_for` method to assign `map_x` and `map_y` instead of `x` and `y`:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.tile_for(tile_x, tile_y, tile_type)
  tile_type.new(
    map_x: tile_x * TILE_WIDTH,
    map_y: tile_y * TILE_HEIGHT,
    w: TILE_WIDTH,
    h: TILE_HEIGHT
  )
end
```
And in the `MotileEntity` change `spawn` to assign `map_x` and `map_y` instead of `x` and `y`:
```ruby
# /ascii/app/entities/motile_entity.rb
def self.spawn(tile_x, tile_y)
  new(
    map_x: tile_x * SPRITE_WIDTH,
    map_y: tile_y * SPRITE_HEIGHT
  )
end
```

This doesn't change much - run the app and see - but gives us a map-relative coordinate to track. So we now need to use _this_ value to move the player. Change the player `tick` to:
```ruby
# /ascii/app/entities/player.rb
def tick(args)
  @map_y += ::Controllers::MapController::TILE_HEIGHT if args.inputs.keyboard.key_down.up || args.inputs.keyboard.key_down.w
  @map_y -= ::Controllers::MapController::TILE_HEIGHT if args.inputs.keyboard.key_down.down || args.inputs.keyboard.key_down.s
  @map_x += ::Controllers::MapController::TILE_WIDTH if args.inputs.keyboard.key_down.right || args.inputs.keyboard.key_down.d
  @map_x -= ::Controllers::MapController::TILE_WIDTH if args.inputs.keyboard.key_down.left || args.inputs.keyboard.key_down.a
end
```

This will break the movement for now, but we'll get to fixing that. First, restore the old behaviour by adding the following lines at the end of the `Player#tick` method:
```ruby
# /ascii/app/entities/player.rb#tick
  # ... etc
  @x = map_x - args.state.map.x
  @y = map_y - args.state.map.y
end
```

We also want the static assets to be able to update their screen X/Y based on the map x/y. So in StaticEntity, add this tick:
```ruby
# /ascii/app/entities/static_entity.rb
def tick(args)
  @x = map_x - args.state.map.x
  @y = map_y - args.state.map.y
end
```

Finally, so this all works, we need to initialize the map x/y by changing the `MapController`'s `load_map` method to:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.load_map(state)
  state.map.tiles = map_tiles
  state.map.x = 0
  state.map.y = 0
end
```

## Moving the 'Camera'
Now that our player can move again, we want the map's position to adjust based on player's position (if necessary).

First we need to create a 'buffer' border around the screen. Moving into the section will make the map move. so in `MapController` add another two constants just below the others (`TILE_WIDTH`, etc):
```ruby
# /ascii/app/controllers/map_controller.rb
MOVEMENT_ZONE_BUFFER_X = 8 * TILE_WIDTH
MOVEMENT_ZONE_BUFFER_Y = 6 * TILE_HEIGHT
```

Add a `tick` to the `MapController`:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.tick(args)
  player = args.state.player
  map = args.state.map
  player_x_offset = player.map_x - map.x
  player_y_offset = player.map_y - map.y
  if player_x_offset < MOVEMENT_ZONE_BUFFER_X
    map.x = [min_x, map.x - TILE_WIDTH].max
  elsif player_x_offset > (1280 - MOVEMENT_ZONE_BUFFER_X)
    map.x = [map.x + TILE_WIDTH, max_x].min
  end
  if player_y_offset < MOVEMENT_ZONE_BUFFER_Y
    map.y = [min_y, map.y - TILE_HEIGHT].max
  elsif player_y_offset > (720 - MOVEMENT_ZONE_BUFFER_Y)
    map.y = [map.y + TILE_HEIGHT, max_y].min
  end
end
```
There's a lot going on this block of code, but basically we are getting the player's screen position (`player.map_x - map.x` and `player.map_y - map.y`), then looking to see if the player is too close to any of the top/left/bottom/right edges. If they are, we bump the map left/right/up/down by a single tile to compensate and keep the player in frame.

and call this in the `Player#tick` right before updating x/y:
```ruby
# /ascii/app/entities/player.rb
def tick(args)
  # ... etc
  ::Controllers::MapController.tick(args)
  @x = map_x - args.state.map.x
  @y = map_y - args.state.map.y
end
```

The static tiles still aren't moving, so at the end of the Map tick, call:
```ruby
# /ascii/app/controllers/map_controller.rb
args.state.map.tiles.flatten.each { |tile| tile.tick(args) }
```
>The tiles on the `state.map` are in a two-dimensional array. We don't care about their x/y tile position for this bit of code, so we use ruby's `flatten` method to turn the 2D array into a 1D array, and just loop through them all calling their `tick` method.

It's kind of hard to see, so let's make the map a little more interesting so we can see more landscape moving. We'll make a 1-in-8 chance of generating a wall tile on the floor. So within the `MapController#map_tiles` method, replace:
```ruby
# /ascii/app/controllers/map_controller.rb#map_tiles
tile_for tile_x, tile_y, ::Entities::Floor
```
with:
```ruby
# /ascii/app/controllers/map_controller.rb#map_tiles
if (0..8).to_a.sample == 0
  tile_for tile_x, tile_y, ::Entities::Wall
else
  tile_for tile_x, tile_y, ::Entities::Floor
end
```
Run the code now, and the landscape will be more interesting.


## Blocking Movement
Next up we're going to look at keeping entities within bounds. To do this we'll create a common `attempt_move` method on `MotileEntity` that can be used to check if the tile is in bounds (and later used for collision detection against other blocking entities - either static or motile).

Before we can do that, we need a way of translating any entity's `map_x, map_y` position into a `tile_x, tile_y` position. I feel like the MapController is a good place to hold this logic, as that's the part of the code that's knowledgable about the tile width, etc. So within `map_controller.rb` add the following method definitions, which convert a world x/y position in pixels into a tile position on the map:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.map_x_to_tile_x(map_x)
  (map_x / TILE_WIDTH).floor
end

def self.map_y_to_tile_y(map_y)
  (map_y / TILE_HEIGHT).floor
end
```
While we're in the `MapController`, we need a way to check if a given tile is blocked. Once we add this method we need a way of setting tiles to either blocking or non-blocking. Add this within `MapController`:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.blocked?(args, tile_x, tile_y)
  return true if tile_x < 0 || tile_x > MAP_WIDTH - 1
  return true if tile_y < 0 || tile_y > MAP_HEIGHT - 1

  tile = args.state.map.tiles[tile_x][tile_y]
  tile.blocking?
end
```
The tile's don't yet know that they're blocking, so go into `Entities::Base` and set the default to false:
```ruby
# /ascii/app/entities/base.rb
def blocking?
  false
end
```

And add this into the `serialize` hash:
```ruby
# /ascii/app/entities/base.rb
def serialize
  {
    x: x,
    y: y,
    w: w,
    h: h,
    path: path,
    blocking: blocking?
  }
end
```
This way most entities will be non-blocking, but for the static ones like walls we can override that method to make them blocking. In `Wall` override this as follows:
```ruby
# /ascii/app/entities/wall.rb
def blocking?
  true
end
```

## Attempting Movement
In `MotileEntity` we now need to add the `attempt_move` method:
```ruby
# /ascii/app/entities/motile_entity.rb
def attempt_move(args, target_x, target_y)
  tile_x = ::Controllers::MapController.map_x_to_tile_x(target_x)
  tile_y = ::Controllers::MapController.map_y_to_tile_y(target_y)
  return if ::Controllers::MapController.blocked?(args, tile_x, tile_y)

  @map_x = target_x
  @map_y = target_y
  yield if block_given?
  @x = map_x - args.state.map.x
  @y = map_y - args.state.map.y
end
```
> We're making use of the `yield` keyword here, on the condition that `block_given?`. This lets us either call `attempt_move(args, tile_x, tile_y)` if we just want its basic behaviour, or call it with a block of additional code to run at the `yield` statement, before running the last two lines of code, by calling it like
```ruby
attempt_move(args, tile_x, tile_y) do
  some_other_function_or_code
end
```

Most entities probably won't use the 'yield', but our player will - to keep the motion smooth we want the player to move, then the map to adjust it's position to keep the player 'in frame', and only then can we calculate the screen x/y of the player entity. If we don't do this, we'll get a very juddery movement where, for a single frame, the player will be drawn outside of the permitted area before the map moves. So, finally, within the player replace the `tick` method with:
```ruby
# /ascii/app/entities/player.rb
def tick(args)
  keyboard = args.inputs.keyboard
  target_x = if keyboard.key_down.right || keyboard.key_down.d
               map_x + ::Controllers::MapController::TILE_WIDTH
             elsif keyboard.key_down.left || keyboard.key_down.a
               map_x - ::Controllers::MapController::TILE_WIDTH
             else
               map_x
             end
  target_y = if keyboard.key_down.up || keyboard.key_down.w
               map_y + ::Controllers::MapController::TILE_HEIGHT
             elsif keyboard.key_down.down || keyboard.key_down.s
               map_y - ::Controllers::MapController::TILE_HEIGHT
             else
               map_y
             end
  attempt_move(args, target_x, target_y) do
    ::Controllers::MapController.tick(args)
  end
end
```
This uses `target_x` and `target_y` to figure out where the player is about to try and move to based on keyboard input, then passes those into `attempt_move` to see if the tile is blocking. Lastly the contents of the `do...end` block gives the `yield` in `attempt_move` something to run, to update the map position based on the player's new map x/y.

Give that a run. The player should no longer be able to move through wall tiles, and the map should scroll nicely.
