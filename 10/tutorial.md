## Introduction

This is the tenth part of a series of tutorials building a top-down 'Roguelike' game. In the previous installments we created a basic framework for our classes, controllers, entities, etc, and got some 'Static Entities' in the form of map tiles drawn on the screen. We have both a Player entity and Enemey entities which are capable of movement, tile-based and entity-to-entity collisions, and can attack one another and take damage. The camera follows the player as the traverse the map. We also took a brief aside to look at some Render Targets.

I recommend you familiarise yourself with the previous parts, and we'll be using the 'final code' from the previous tutorial as our starting point here.

Next up we're going to start using our right-hand panel for displaying events, stats etc.

## Player Stats
First up, let's extend the `Defender` behaviour to set a `max_hp` attribute, as we'll want to show HP remaining, and let us do some neat colouring.

```ruby
# /ascii/app/behaviour/defender.rb
attr_reader :max_hp, :hp, :defense
```

Then in `Player` we need to set the `max_hp` within the `initialize` method:
```ruby
# /ascii/app/entities/player.rb
def initialize(opts = {})
  # ...etc
  @max_hp = 50
  @hp = max_hp
  # ...etc
end
```

And likewise in `Enemy`:
```ruby
# /ascii/app/entities/enemy.rb
def initialize(opts = {})
  # ...etc
  @max_hp = 10
  @hp = max_hp
  # ...etc
end
```

For now we just want the HP stats, but we may want to expand this further, so add a `stats_labels` method to the `Player`:
```ruby
# /ascii/app/entities/player.rb
def stats_labels
  [
    [16, 700, hp_string, 255, 255, 255, 255]
  ]
end
```
> The attributes here are `[x, y, string, red, green, blue, alpha]`

Next we need to populate the HP string. I'm choosing to 'pad' the HP to two digits, to produce an HP like `HP: 07/50`

```ruby
# /ascii/app/entities/player.rb
def hp_string
  hp_label = hp < 10 ? "0#{hp}" : hp.to_s
  max_hp_label = max_hp < 10 ? "0#{max_hp}" : max_hp.to_s
  "HP: #{hp_label} / #{max_hp_label}"
end
```

Render the logs to the panel within the `GameController`'s `render_text_area` method:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.render_text_area(args)
  args.render_target(:text_area).solids << [0, 0, TEXT_AREA_WIDTH, TEXT_AREA_HEIGHT, 10, 21, 33]
  args.render_target(:text_area).labels << args.state.player.stats_labels
end
```

Finally, for a nice touch, let's color-code the HP string. Change the `stats_labels` method to:
```ruby
# /ascii/app/entities/player.rb
def stats_labels
  [
    [16, 700, hp_string].concat(hp_string_color)
  ]
end
```
And populate an `hp_string` method, which will return Green if HP is above 50%, orange between 20% and 50%, and red under 20%.
```ruby
# /ascii/app/entities/player.rb
def hp_string_color
  if hp / max_hp >= 0.5
    [10, 200, 10, 255]
  elsif hp / max_hp >= 0.2
    [255, 165, 0, 255]
  else
    [220, 0, 0, 255]
  end
end
```

Run the game, get a little beaten up, and enjoy the colours.

## Events
We want to fill the panel with a history of the last X events. This will require storing the events on the `state`, drawing them to the panel, and perhaps occasionally pruning them. We'll start with an `EventLogsController` which will be responsible for initializing the state, for logging new events, and for producing a rendering of the X most recent events.

Create a new file at `app/controllers/event_logs_controller.rb`:
```ruby
# /ascii/app/controllers/event_logs_controller.rb
module Controllers
  class EventLogsController
    def self.render(args, sprites, labels)
    end

    def self.reset(state)
      state.event_logs = []
    end
  end
end
```

Include the `EventLogsController` in `main.rb`, along with the other `Controller` includes:
```ruby
# /ascii/app/main.rb
require 'app/controllers/event_logs_controller.rb'
```

Call the `reset` method from within the `GameController`'s `reset` method:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.reset(state)
  ::Controllers::EventLogsController.reset(state)
  # ...etc
end
```

Add a `log_event` method to the `EventLogsController`, which just puts any new log into position 0 in the array (so the array is naturally a list of newest to oldest):

```ruby
# /ascii/app/controllers/event_logs_controller.rb
def self.log_event(event)
  $gtk.args.state.event_logs.unshift(event)
end
```

We want a way of turning all event logs into labels, so they can be displayed in our panel on render. So add an `events_as_labels` method to the `EventLogsController`:
```ruby
# /ascii/app/controllers/event_logs_controller.rb
LOG_TOP = 650

def self.events_as_labels(events)
  events.map.with_index do |event, index|
    alpha = 255 - (index * 15)
    [16, LOG_TOP - (index * 40), event, 230, 230, 230, alpha]
  end
end
```

The changing alpha just makes the most recent events appear a white, and the older events appear as dark grey. Finally, for the `EventLogsController`, fill out the render method:
```ruby
# /ascii/app/controllers/event_logs_controller.rb
def self.render(args, sprites, labels)
  labels << events_as_labels(args.state.event_logs[0..20])
end
```

We don't have any logs yet, but before we do let's get the last mechanism in place: calling the `EventLogsController`'s `render` method in `GameController#render_text_area`
```ruby
# /ascii/app/controllers/game_controller.rb
def self.render_text_area(args)
  args.render_target(:text_area).solids << [0, 0, TEXT_AREA_WIDTH, TEXT_AREA_HEIGHT, 10, 21, 33]
  labels = []
  labels << args.state.player.stats_labels
  ::Controllers::EventLogsController.render(args, [], labels)
  args.render_target(:text_area).labels << labels
end
```

## Attack Events

For our `puts` that we've been using so far, we've been using the class name, but this isn't going to look great in the logs when we show `Entities::Zombie` or whatever. So let's add a `name` Class Method to the `Base`, `Enemy`, `Zombie` and `Player` classes:
```ruby
# /ascii/app/entities/base.rb
def self.name
  ''
end
```

```ruby
# /ascii/app/entities/enemy.rb
def self.name
  'Enemy'
end
```

```ruby
# /ascii/app/entities/zombie.rb
def self.name
  'Zombie'
end
```

```ruby
# /ascii/app/entities/Player.rb
def self.name
  'Player'
end
```

To create Event Logs for out attacks, head over to the `Attacker` behaviour, and add the following two calls to `log_event`.
```ruby
if roll >= other.defense
  other.take_damage(total_attack)
  ::Controllers::EventLogsController.log_event(
    "#{roll == 20 ? 'CRIT! ' : ''}#{self.class.name} hit #{other.class.name} for #{total_attack} damage"
  )
else
  ::Controllers::EventLogsController.log_event(
    "#{self.class.name} missed #{other.class.name}!"
  )
end
```

Remove the `puts` from the `Attacker` behaviour, and the one from the `Defender` behaviour.

## Spawning Safely
At the moment, players, enemies, etc can spawn anywhere, even on top of a wall piece. So we want to check whether a tile is `blocked` before spawning.

In `GameController`'s `reset` method replace the naive `state.player = ::Entities::Player.spawn(tile_x, tile_y` with:
```ruby
# /ascii/app/controllers/game_controller.rb#reset
tile_x = (1..15).to_a.sample
tile_y = (1..15).to_a.sample
while state.map.tiles[tile_x][tile_y].blocking?
  tile_x = (1..15).to_a.sample
  tile_y = (1..15).to_a.sample
end
state.player = ::Entities::Player.spawn(tile_x, tile_y)
```

And within the `EnemyController`'s `spawn_enemies` method, add a loop just after the tile_x/tile_y are randomized to re-calc them if they lead to a blocked tile:
```ruby
# /ascii/app/controllers/enemy_controller.rb#spawn_enemies
tile_x = (::Controllers::MapController::MAP_WIDTH * rand).floor
tile_y = (::Controllers::MapController::MAP_HEIGHT * rand).floor
while state.map.tiles[tile_x][tile_y].blocking?
  tile_x = (::Controllers::MapController::MAP_WIDTH * rand).floor
  tile_y = (::Controllers::MapController::MAP_HEIGHT * rand).floor
end
```
