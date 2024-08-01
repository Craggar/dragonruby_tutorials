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
    {x: 16, y: 700, text: hp_string, r: 255, g: 255, b: 255, a: 255}
  ]
end
```
> The attributes here are `[x, y, string, red, green, blue, alpha]`

Next we need to populate the HP string. I'm choosing to 'pad' the HP to two digits, to produce an HP like `HP: 07/50`

```ruby
# /ascii/app/entities/player.rb
def hp_string
  hp_label = (hp < 10) ? "0#{hp}" : hp.to_s
  max_hp_label = (max_hp < 10) ? "0#{max_hp}" : max_hp.to_s
  "HP: #{hp_label} / #{max_hp_label}"
end
```

Render the logs to the panel within the `GameController`'s `render_text_area` method:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.render_text_area(args)
  args.state.redraw_text_area = false
  args.render_target(:text_area).solids << [0, 0, TEXT_AREA_WIDTH, TEXT_AREA_HEIGHT, 10, 21, 33]
  args.render_target(:text_area).labels << args.state.player.stats_labels
end
```

Finally, for a nice touch, let's color-code the HP string. Create an `hp_string` method, which will return Green if HP is above 50%, orange between 20% and 50%, and red under 20%.
```ruby
# /ascii/app/entities/player.rb
def hp_string_color
  if hp / max_hp >= 0.5
    {r: 10, g: 200, b: 10, a: 255}
  elsif hp / max_hp >= 0.2
    {r: 255, g: 165, b: 0, a: 255}
  else
    {r: 220, g: 0, b: 0, a: 255}
  end
end
```

Then Change the `stats_labels` method to:
```ruby
# /ascii/app/entities/player.rb
def stats_labels
  [
    {x: 16, y: 700, text: hp_string}.merge(hp_string_color)
  ]
end
```


Run the game, get a little beaten up. Wait, why is the label just saying "50/50" despite the logs saying the Player is taking damage? It's because we're being economical and using render targets, and the text area is only redrawn when we set `args.state.redraw_text_area = true`. So let's set that to true whenever the player takes damage.

First, let's track whether the player took damage, in the same way we track whether they 'took_action', by adding a `took_damage` attribute to the `Player` class:
```ruby
# /ascii/app/entities/player.rb
attr_reader :took_action, :took_damage
```

Make sure we set `took_damage` to `false` at the start of each tick:
```ruby
# /ascii/app/entities/player.rb
def tick(args)
  @took_action = false
  @took_damange = false
  # ...etc
end
```

Then set `took_damage` to `true` whenever the player takes damage by extending the `take_damage` method inherited from `Defender`:
```ruby
# /ascii/app/entities/player.rb
def take_damage(damage)
  super
  @took_damage = true
end
```

Finally, set `args.state.redraw_text_area` to `true` whenever the player takes damage by checking this attribute in the GameController:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.tick(args)
  args.state.player.tick(args)
  if args.state.player.took_damage
    args.state.redraw_text_area = true
  end
  ::Controllers::EnemyController.tick(args)
end
```

(we could also do that with a one-liner as `args.state.redraw_text_area ||= args.state.player.took_damage`, but I'll leave the clearer version in place for now).

Now give the game a run, get beaten up, and see the HP change text _and_ colour. If it's not dramatic enough for you, you can always adjust the damage dealt by the enemies to move the HP bar more quickly, change the ratios at which the color changes happen, or lower the player's max HP.

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
      state.logged_event_this_tick = false
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

Add a `log_event` method to the `EventLogsController`, which just puts any new log into position 0 in the array (so the array is naturally a list of newest to oldest), and sets our flag to say there was an event logged this tick:

```ruby
# /ascii/app/controllers/event_logs_controller.rb
def self.log_event(event)
  $gtk.args.state.event_logs.unshift(event)
  $gtk.args.state.logged_event_this_tick = true
end
```

We want a way of turning all event logs into labels, so they can be displayed in our panel on render. So add an `events_as_labels` method to the `EventLogsController`:
```ruby
# /ascii/app/controllers/event_logs_controller.rb
LOG_TOP = 650

def self.events_as_labels(args)
  args.state.event_logs.map.with_index do |event, index|
    alpha = 255 - (index * 15)
    {x: 16, y: LOG_TOP - (index * 40), text: event, r: 230, g: 230, b: 230, a: alpha}
  end
end
```

The changing alpha just makes the most recent events appear a white, and the older events appear as dark grey.

We don't have any logs yet, but before we do let's get the last mechanism in place: calling the `EventLogsController`'s `events_as_labels` method in `GameController#render_text_area` to pull through all those lovely labels:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.render_text_area(args)
  args.state.redraw_text_area = false
  args.render_target(:text_area).solids << {x: 0, y: 0, w: TEXT_AREA_WIDTH, h: TEXT_AREA_HEIGHT, r: 10, g: 21, b: 33}
  args.render_target(:text_area).labels << args.state.player.stats_labels
  args.render_target(:text_area).labels << ::Controllers::EventLogsController.events_as_labels(args)
end
```

While we're in here, here we need to clear the `logged_event_this_tick` flag at the start of the tick:
```ruby
# /ascii/app/controllers/game_controller.rb
def self.tick(args)
  args.state.logged_event_this_tick = false
  # ...etc
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

To create Event Logs for out attacks, head over to the `Attacker` behaviour, and add the following two calls to `log_event` from the `deal_damage` method.
```ruby
# /ascii/app/behaviour/attacker.rb
if roll >= other.defense
  other.take_damage(total_attack)
  ::Controllers::EventLogsController.log_event(
    "#{roll == 20 ? 'CRIT! ' : ''}#{name} hit #{other.name} for #{total_attack} damage"
  )
else
  ::Controllers::EventLogsController.log_event(
    "#{name} missed #{other.name}!"
  )
end
```

Remove the `puts` from the `Attacker` behaviour, and the one from the `Defender` behaviour.

![A screenshot showing the player's HP color-coded, along with a log of events from most recent to oldest, fading from white to black based on their recency](./screenshots/logs_and_hp_color.png)
