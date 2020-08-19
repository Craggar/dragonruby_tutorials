## Introduction

This is the fourth part of a series of tutorials building a top-down 'Roguelike' game. In the previous installments we created a basic framework for our classes, controllers, entities, etc, and got some 'Static Entities' in the form of map tiles drawn on the screen, and got our player entity rendered and moving around the screen, making the map/camera follow the player, and enabling tile-based collisions with the map. We also added our first enemies, and gave them a basic random movement/patrol behaviour and a 'seek player' behaviour, as well as introducing the concept of entities 'occupying' a tile, preventing other entities moving into them, to form our basic entity-to-entity collision. We also took a brief aside to look at some Render Targets.

I recommend you familiarise yourself with the previous parts, and we'll be using the 'final code' from the previous tutorial as our starting point here.

Next up we're going to build out some of the 'Behaviours' to give our players and enemies Hit Points/Health, enable them to deal and take damage.

## Defensive Behaviour
We want to add Hit Points to enemies, players, and perhaps beyond (destructible walls?). While we're at it, we probably want to add a concept of a defense attribute, in the classic D&D style. So, let's create a `Defender` behaviour at `/app/behaviour/defender.rb`, give anything that includes it an `hp` and `defense` attribute, as well as a simple helper `alive?` that returns false once HP hits `0`
```ruby
# /ascii/app/behaviour/defender.rb
module Behaviour
  module Defender
    attr_reader :hp, :defense

    def alive?
      hp > 0
    end
  end
end
```

Defenders also need to be able to take damage, so let's add a method to take a given amount of damage, and log the damage via `puts` (this will later go in our logger pane on the right):
```ruby
# /ascii/app/behaviour/defender.rb
def take_damage(damage)
  @hp = [
    0,
    hp - damage
  ].max
  puts "#{self.class} took #{damage} damage -> #{hp} remaining"
end
```

Include the `defender` behaviour in `main.rb`, ensuring you again include it before any of the `Entity` includes:
```ruby
# /ascii/app/main.rb
require 'app/behaviour/defender.rb'
```

We want our enemies and our Player to have `defender` behaviour, so they have HP and can take damage. So within `Enemy` include the behaviour, and set these new attributes in a new `initialize` method
```ruby
# /ascii/app/entities/enemy.rb
module Entities
  class Enemy < MotileEntity
    include ::Behaviour::Defender
    VISIBLE_RANGE = 300

    def initialize(opts = {})
      super
      @hp = 10
      @defense = 0
    end
    # ...etc
```

I'm going to give our Zombie slightly better defense:
```ruby
# /ascii/app/entities/zombie.rb
def initialize(opts = {})
  super
  @path = 'app/sprites/zombie.png'
  @defense = 4
end
```

And finally our player, whom I'm giving 50 HP and 10 DEF:
```ruby
# /ascii/app/entities/player.rb
module Entities
  class Player < MotileEntity
    include ::Behaviour::Defender

    attr_reader :took_action

    def initialize(opts = {})
      super
      @path = 'app/sprites/player.png'
      @hp = 50
      @defense = 10
    end
    # ...etc
```
## Attacking behaviour
Next we want to be able to actually deal damage. So let's create an attacker behaviour at `/app/behaviour/attacker.rb`, give anything that includes it an `attack` attribute:
```ruby
# /ascii/app/behaviour/attacker.rb
module Behaviour
  module Attacker
    attr_reader :attack
  end
end
```
As an attacker, we need to be able to deal damage to an `other`, so add a basic `deal_damage` method, which takes another entity as a parameter.
```ruby
# /ascii/app/behaviour/attacker.rb
def deal_damage(other)
  other.take_damage(attack)
end
```

Include the `attacker` behaviour in `main.rb`, ensuring you again include it before any of the `Entity` includes:
```ruby
# /ascii/app/main.rb
require 'app/behaviour/attacker.rb'
```

Then include the Attacker behaviour in `Player`:
```ruby
# /ascii/app/entities/player.rb
module Entities
  class Player < MotileEntity
    include ::Behaviour::Defender
    include ::Behaviour::Attacker
```

In initialize, set the new attribute `attack` on the `Player` entity:
```ruby
# /ascii/app/entities/player.rb
def initialize(opts = {})
  super
  @path = 'app/sprites/player.png'
  @hp = 50
  @defense = 10
  @attack = 3
end
```

We also want enemies to be able to attack, so add the behaviour in `Enemy`:
```ruby
# /ascii/app/entities/enemy.rb
module Entities
  class Player < MotileEntity
    include ::Behaviour::Defender
    include ::Behaviour::Attacker
```

And in initialize, set the new attribute `attack` on the base `Enemy` entity:
```ruby
# /ascii/app/entities/enemy.rb
def initialize(opts = {})
  super
  @hp = 10
  @defense = 0
  @attack = 1
end
```

## Can I hurt it? Can it hurt me?
We want a way to know whether an entity can deal and/or take damage - when we try to move and are obstructed, it could be by a wall, or an NPC, or something else that blocks our way. If it's an enemy, though, we want to attack it. So we need to know if it can `take_damage`.

Ruby provides a neat helper `respond_to?`, which let's you ask if an object has a method on it. Sadly, that's not available in DR GTK right now, but we can implement it ourselves. Within `Entities::Base`, add this:
```ruby
# /ascii/app/entities/base.rb
def respond_to?(method)
  self.class.method_defined?(method.to_sym)
end
```
> Hopefully fairly self explanatory, but this lets any instance of a class that inherits from `Entities::Base` ask it's `Class` whether the given method exists.

To use this, we're going to have to be able to get the occupant of the tile we are trying to move towards, so we can then check if we can hurt whatever is blocking us. We're going to split the `MapController`'s `blocked?` method out so we have a separate `tile_at` method that we can re-use:
```ruby
# /ascii/app/controllers/map_controller.rb
def self.blocked?(args, tile_x, tile_y)
  tile = tile_at(args, tile_x, tile_y)
  return true unless tile

  tile.blocking?
end

def self.tile_at(args, tile_x, tile_y)
  return nil if tile_x < 0 || tile_x > MAP_WIDTH - 1
  return nil if tile_y < 0 || tile_y > MAP_HEIGHT - 1

  tile = args.state.map.tiles[tile_x][tile_y]
end
```

With that in place, we want to leverage this new `tile_at` method, as well as the `respond_to?` to see if the tile at that location has the `Occupant` behaviour, by testing if it responds to `.occupant` (to see if it's a floor tile, rather than a wall):

```ruby
# /ascii/app/controllers/map_controller.rb
def self.tile_occupant(args, tile_x, tile_y)
  tile = tile_at(args, tile_x, tile_y)
  return nil unless tile && tile.respond_to?(:occupant)

  tile.occupant
end
```

And we want to make sure that when an attacker attacks something, we can actually attack it:
```ruby
# /ascii/app/behaviour/attacker.rb
def deal_damage(other)
  return unless other.respond_to?(:take_damage)

  other.take_damage(attack)
end
```

## (Actually) Attack!

Now we can check if things can be hurt, and we can get the occupant of a blocking tile, we want to hurt them. We're going to extend the `attempt_move` method, and give it a better name as it will be attacking too. So we're going to rename it to `move_or_attack` within the `app/entities/motile_entity.rb`, and make sure you update the calls to this method in both `player.rb` and `enemy.rb`.

And now we expand this renamed `move_or_attack` method:
```ruby
# /ascii/app/entities/motile_entity.rb
def move_or_attack(args, target_x, target_y)
  tile_x = ::Controllers::MapController.map_x_to_tile_x(target_x)
  tile_y = ::Controllers::MapController.map_y_to_tile_y(target_y)
  if ::Controllers::MapController.blocked?(args, tile_x, tile_y)
    other = ::Controllers::MapController.tile_occupant(args, tile_x, tile_y)
    if respond_to?(:deal_damage) && other
      deal_damage(other)
      yield
    end
  else
    @map_x = target_x
    @map_y = target_y
    yield if block_given?
  end
  @x = map_x - args.state.map.x
  @y = map_y - args.state.map.y
end
```
Here we've removed the 'return' if the tile is blocked, and instead branched to an `if blocked <attack> else <move>`, but we're useing `respond_to?` to check that the entity moving can actually attack (`respond_to?(:deal_damage)`) before doing so, and the `deal_damage` method makes sure the `other` can `take_damage`.

Have a play, watch the console output, and you'll see our logs that player and zombies are taking and dealing damage.
