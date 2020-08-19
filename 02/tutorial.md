## Introduction
This is the second part of a series of tutorials building a top-down 'Roguelike' game. In the first part where the basic project structure was established, this tutorial continues from there. I recommend you familiarise yourself with the first part, and we'll be using the 'final code' from the previous tutorial as our starting point here.

This tutorial will start with the first entities, starting with a core entity that can be built on for other entities.

## Enter the Entities
So, create a new folder `/app/entities` and create a file called `base.rb`. Within that file, add the following:
```ruby
# /ascii/app/entities/base.rb
module Entities
  class Base
    attr_sprite
  end
end
```
>Once again, namespacing our entities, to make a clear distinction between these types of objects and our Controllers.

> We're using the `attr_sprite` mixin which lets us treat our entities as sprites, without having to do much transforming, or manually producing a hash/array. It automatically gives you x, y, w (width), h (height), path (sprite image path) attributes on your model

There will be plenty of entity types, but I want to start with two core distinctions: static entities (walls, floor, etc) and motile entities (players, enemies, projectiles). Using these base classes for future inheritance lets us group behaviours that are common to their inheritors. So let's start with a static entity, and two types of static entities - walls and floors.

Create a file at `/app/entities/static_entity.rb`, and fill it with the following code.

```ruby
# /ascii/app/entities/static_entity.rb
module Entities
  class StaticEntity < Base
  end
end

```
> `class StaticEntity < Base` inherits any behaviours or attributes from the `Base` entity (like that handy `attr_sprite` mixin), but also lets us override or extend them, which we'll get to later.

Next, we should include these in `main.rb`. Just after the block of controller includes, add the entities:
```ruby
# /ascii/app/main.rb
require 'app/entities/base.rb'
require 'app/entities/static_entity.rb'
```

As we will be drawing these entities as sprites, we want to set `SPRITE_WIDTH` and `SPRITE_HEIGHT` constants for all entities. In this project every sprite will take up a full tile height/width, so it makes sense to define them at the `Base` level, but in other projects you might have different sized sprites, and local defines might make more sense. Add them near the top of the class, like this:
```ruby
# /ascii/app/entities/base.rb
module Entities
  class Base
    attr_sprite

    SPRITE_WIDTH = 32
    SPRITE_HEIGHT = 32

    # the rest of the code follows here
```

We're going to be using all these entities to create the map, but of course we want to be able to create everything at specific locations, and set certain attributes. We'll create a core `initialize` method in the Entities::Base object, and we can override/extend this in other classes. So, open `entities/base.rb` and add an `initialize` method:

```ruby
# /ascii/app/entities/base.rb
def initialize(opts = {})
  @x = opts[:x] || 0
  @y = opts[:y] || 0
  @w = opts[:w] || SPRITE_WIDTH
  @h = opts[:h] || SPRITE_HEIGHT
  @path = opts[:path] || 'app/sprites/null_sprite.png'
end
```

Note the `app/sprites/null_sprite.png` - you'll find this in the example project folder - it's just an invisible sprite.

We can now create base entities with `Entities::Base.new(...)`, but we don't want to do that - we want to use specific entities. Let's expand our static entities with a `Floor` and a `Wall` type.

Create `/app/entities/wall.rb` with the following code in it.
```ruby
# /ascii/app/entities/wall.rb
module Entities
  class Wall < StaticEntity
  end
end

```

And similarly for `/app/entities/static/floor.rb`:
```ruby
# /ascii/app/entities/floor.rb
module Entities
  class Floor < StaticEntity
  end
end

```

Make sure to include these in `main.rb`:
```ruby
# /ascii/app/main.rb
require 'app/entities/wall.rb'
require 'app/entities/floor.rb'
```

The main way these differ from their 'parent' (`Entities::Base`) - for now at least - is that they show a different sprite. In `floor.rb` add the following `initialize` method:
```ruby
# /ascii/app/entities/floor.rb
def initialize(opts = {})
  super
  @path = 'app/sprites/floor.png'
end
```
And similar for the `wall.rb`:
```ruby
# /ascii/app/entities/wall.rb
def initialize(opts = {})
  super
  @path = 'app/sprites/wall.png'
end
```
> When inheriting from another class - as we do here with `class Wall < Base` and `class Floor < Base`, if we don't define an `initialize` in `Floor` or `Wall`, they will call the method in `Base`. We can completely override the parent `initialize` method by declaring one locally wihin `Wall` or `Floor`, but we actually want to use _most_ of the `Base#initialize` method (to set x, y, etc) - we only want to change the `@path`. These two classes, as shown above, leverage the `Entities::Base#initialize` method by first calling `super`, which calls the parent's initialize method, then overrides the sprite `@path` to set their own image.

Note: The `floor.png` and `wall.png` can be found in the example code, again.

## Creating a Map
Next up, to draw our map, we want a Map Controller. This will be used to populate the `state` with tiles, and to do some helper methods for navigating the map. Add a file at `app/controllers/map_controller.rb`, and make sure to add `require` line in `main.rb` again:
```ruby
# /ascii/app/main.rb
require 'app/controllers/map_controller.rb'
```

Fill the MapController with this:
```ruby
# /ascii/app/controllers/map_controller.rb
module Controllers
  class MapController
    MAP_WIDTH = 80
    MAP_HEIGHT = 45
    TILE_WIDTH = 32
    TILE_HEIGHT = 32

    def self.load_map(state)
    end
  end
end
```
The `MAP_WIDTH` and `MAP_HEIGHT` are the map size in _tiles_. The `TILE_WIDTH` and `TILE_HEIGHT` are the size of _each tile_ in _pixels_.

The `MAP_WIDTH` and `MAP_HEIGHT` for this example just equate to 2 screens wide and 2 screens high, as we'll ultimately make this map scroll about as the player moves.

Add a method in the MapController:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.map_tiles
  MAP_WIDTH.times.map do |tile_x|
    MAP_HEIGHT.times.map do |tile_y|
    end
  end
end
```
> The ruby `times` keyword is another nice example of the ruby's language/grammar. You can basically say "Do this thing `8.times`". Here we're doing both `MAP_WIDTH` and `MAP_HEIGHT` times, so the outer loop runs `80.times` and the inner loop runs `45.times`.

> We're coupling that with ruby's `.map` method, which gathers the return value of the loop into an Array. Because we have a nested loop, we're creating a two-dimentional array.

This nested loop loops through the number of horizonal tiles, and then the number of vertical tiles. By doing a couple of `.map` here we can basically produce a grid of tiles, something like (if this helps). To understand how this translates to on-screen, rotate it 90 degees counter-clockwise, and imagine each number as a tile on the map.
```ruby
[
  [0,0,0,0,0,0,0,0],
  [0,1,1,1,1,1,1,0],
  [0,1,1,1,1,1,1,0],
  [0,1,1,1,1,1,1,0],
  [0,1,1,1,1,1,1,0],
  [0,1,1,1,1,1,1,0],
  [0,1,1,1,1,1,1,0],
  [0,0,0,0,0,0,0,0]
]
```
Where a `0` is a wall and a `1` is the floor. To put a wall all around this floor area, we want any edge tile (where `x = 0`, or `x = MAP_WIDTH -1`, or where `y = 0` or `y = MAP_HEIGHT - 1`). Extend the `map_tiles` method as follows:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.map_tiles
  MAP_WIDTH.times.map do |tile_x|
    MAP_HEIGHT.times.map do |tile_y|
      if tile_y == 0 || tile_y == MAP_HEIGHT - 1 || tile_x == 0 || tile_x == MAP_WIDTH - 1
        # This is the left, right, top or bottom edge, so make a wall
        tile_for(tile_x, tile_y, ::Entities::Wall)
      else
        # it's not the edge, so make it floor
        tile_for(tile_x, tile_y, ::Entities::Floor)
      end
    end
  end
end
```

and add a `tile_for` method to the `MapController`. This takes a tile x/y co-ordinate, and a tile tile (wall or floor), and returns an instance of the appropriate Static Entity.
```ruby
# /ascii/app/controllers/map_controller.rb
def self.tile_for(tile_x, tile_y, tile_type)
  tile_type.new(
    x: tile_x * TILE_WIDTH,
    y: tile_y * TILE_HEIGHT,
    w: TILE_WIDTH,
    h: TILE_HEIGHT
  )
end
```
With that, the last thing to do to get our tiles showing is to 1) initialize the map, and 2) render the sprites.

Change the `MapController`'s' `load_map` method to pull in the map tiles to the state:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.load_map(state)
  state.map.tiles = map_tiles
end
```
and call `load_map` from the `GameController`'s `reset` method:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.reset(state)
  ::Controllers::MapController.load_map(state)
end
```

Finally, render the tile sprites within the `GameController`:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.render(state, sprites, labels)
  sprites << state.map.tiles
end
```
It might not be terribly exciting to look at, but we have a collection of wall tiles round the left and bottom edge, and floor tiles everywhere else. If you're not seeing anything here, make sure you've copied the `floor.png` and `wall.png` from the example folder into your `app/sprites` directory.

## Helping Out the Debugger
When something goes wrong - and it will at some point, either in following this tutorial, or in your own code - DR GTK will attempt to dump the state as a string. In order to do this it expects objects to have three methods to assist with the serialization. These are:
```ruby
def serialize
   { }
 end

 def inspect
  # Override the inspect method and return ~serialize.to_s~.
   serialize.to_s
 end

 def to_s
  #  Override to_s and return ~serialize.to_s~.
   serialize.to_s
 end
```

We actually want something useful in our serialization, though, so let's pad out the serialize method. Add those methods within `Entities::Base`. We want to know the basic sprite attributes: x, y, w (width), h (height), path:
```ruby
# /ascii/app/entities/base.rb
def serialize
  {
    x: x,
    y: y,
    w: w,
    h: h,
    path: path
  }
end

def inspect
  # Override the inspect method and return ~serialize.to_s~.
  serialize.to_s
end

def to_s
  #  Override to_s and return ~serialize.to_s~.
  serialize.to_s
end
```

That wraps it up for Part 2 - in Part 3 we'll start adding a player entity.
