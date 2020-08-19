## Introduction

This is the ninth part of a series of tutorials building a top-down 'Roguelike' game. In the previous installments we created a basic framework for our classes, controllers, entities, etc, and got some 'Static Entities' in the form of map tiles drawn on the screen. We have both a Player entity and Enemey entities which are capable of movement, tile-based and entity-to-entity collisions, and can attack one another and take damage. The camera follows the player as the traverse the map. We also took a brief aside to look at some Render Targets.

I recommend you familiarise yourself with the previous parts, and we'll be using the 'final code' from the previous tutorial as our starting point here.

Next up we're going to handle death, move to dice rolls for attack, and add 'factions' so that players, enemies, etc don't accidentally kill people on their own 'team'.

## Of Dice and Death
This would be a good title for our little game... Anyway.

## Dice
We want to move to attack rolls, that have to overwhelm an enemies 'defense' stat to deal damage. So, first up let's create a base 'dice' class:
```ruby
# /ascii/app/dice/dice.rb
class Dice
  def self.roll(count)
    total = 0
    count.times do
      total += (min_value..max_value).to_a.sample
    end
    total
  end

  def self.min_value
    1
  end

  def self.max_value
    6
  end
end
```
Each type of Die will have a min and max value, and use this 'roll' method to return the total value of 'rolling' itself `count` times.

Let's add our first 'proper' Die the D20 (20-sided dice):
```ruby
# /ascii/app/dice/d20.rb
class D20 < Dice
  def self.max_value
    20
  end
end
```

Include the `Dice` and `D20` in `main.rb`, ensuring you again include it before any of the `Behaviour` includes:
```ruby
# /ascii/app/main.rb
require 'app/dice/dice.rb'
require 'app/dice/d20.rb'
```

We want to use these dice in the `Attacker` behaviour, so open that up, and let's refactor the `deal_damage` method:
```ruby
# /ascii/app/behaviour/attacker.rb
def deal_damage(other)
  return unless other.respond_to?(:take_damage)

  roll = ::D20.roll(1)
  puts "Rolled: #{roll} against #{other.class}'s DEF: #{other.defense}'"
  if roll >= other.defense
    other.take_damage(attack)
  else
    puts 'miss!'
  end
end
```
Instead of just dealing damage to the `other`, we now roll a D20. If the value matches or beats their defense, they take damage, otherwise the attack misses.

Let's also add 'critical' rolls. Within the `Attacker` behaviour, add another `attr_reader` attribute:
```ruby
# /ascii/app/behaviour/attacker.rb
attr_reader :attack, :crit
```

And set that value for both `Player` and `Enemy`:
```ruby
# /ascii/app/entities/player.rb
def initialize(opts = {})
  # ...etc
  @crit = 1
end
```

```ruby
# /ascii/app/entities/enemy.rb
def initialize(opts = {})
  # ...etc
  @crit = 1
end
```

And let's make use of this new value, on a 20 roll:
```ruby
# /ascii/app/behaviour/attacker.rb
def deal_damage(other)
  return unless other.respond_to?(:take_damage)

  roll = ::D20.roll(1)
  puts "Rolled: #{roll == 20 ? 'CRIT!' : roll} against #{other.class}'s DEF: #{other.defense}"
  total_attack = if roll == 20
                   attack + crit
                 else
                   attack
                 end
  if roll >= other.defense
    other.take_damage(total_attack)
  else
    puts 'miss!'
  end
end
```

## Death on 0 HP (for Enemies)
You'll notice that although you can knock the enemy HP down, they never die. So let's fix that.

I think we can all agree that enemies should probably only be able to do anything if they're alive, so update the `Enemy`'s `tick` method:
```ruby
# /ascii/app/entities/enemy.rb
def tick(args)
  if alive?
    act(args)
    @x = map_x - args.state.map.x
    @y = map_y - args.state.map.y
  else
    free_tile_on_death(args)
  end
end
```

As you can see here, we want to free up the tile an enemy occupies on it's death. We'll add that under the `Occupant` behaviour:
```ruby
# /ascii/app/behaviour/occupant.rb
def free_tile_on_death(args)
  tile.occupant = nil
end
```

And finally, we want to clear out the list of 'dead' enemies. We can do this in the `EnemyController`'s `tick` method:
```ruby
# /ascii/app/controllers/enemy_controller.rb
def self.tick(args)
  return unless args.state.player.took_action

  args.state.enemies.each { |enemy| enemy.tick(args) }
  args.state.enemies = args.state.enemies.select(&:alive?)
end
```
After the enemies have acted (so a dead enemy can clear it's occupied tile), we whittle the list of enemies down to just those alive, so the dead will not longer be drawn, or move, or occupy tiles, etc.


## Factions
Watching the logging you might spot zombies hitting zombies. We probably don't want that to happen, broadly speaking - though it might be a nice idea to have 'lawless' Entities that will attack anything they see. But for a start, we want to basically create a `player` faction and an `enemy` faction, so they don't hurt each other.

In `Entities::Base` add a basic faction definiton:
```ruby
# /ascii/app/entities/base.rb
def faction
  'neutral'
end
```

Override this within `Player`:
```ruby
# /ascii/app/entities/player.rb
def faction
  'player'
end
```

And override it within `Enemy`:
```ruby
# /ascii/app/entities/player.rb
def faction
  'enemy'
end
```

Then, to stop factions attacking each other (and we'll make them leave the neutrals alone), we change the `MobileEntity`'s `move_or_attack` to be wary of the factions:
```ruby
# /ascii/app/behaviour/mobile_entity.rb
if respond_to?(:deal_damage) && other && (other.faction != 'neutral' && other.faction != faction)
  deal_damage(other)
  yield
end
```
