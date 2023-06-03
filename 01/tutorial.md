## Introduction
We're going to be building a top-down 'Roguelike' game where movement is on a tile-by-tile, turn-by-turn basis. I'm going to assume you are familiar enough with DragonRuby GTK (GTK from here on out) that you know how to launch a project from the command line. What I'm not going to assume is a deep knowledge of Ruby, so I'll try and explain some core concepts and language features as they are introduced.

> I'll do any Ruby/GTK explainers in these inline sections, like this.

Finally, a disclaimer: This is only _a_ way of doing things - it's not even _my_ only way doing things, let alone _the_ only way of doing things. There may be best/better practices elsewhere, but I'm hoping to help you build something quickly, and learn some of the core concepts of both Ruby and GTK.

## Getting Started
To start with, we want a new game folder. Create a new folder called `ascii` and within it create the `app` folder. Then create a file called: `main.rb`. We need a `Game` class to instantiate, so add the following skeleton code:

Within `main.rb` add the following:
```ruby
# /ascii/app/main.rb

class Game
  def tick(args)
    sprites = []
    labels = []
    render(args, sprites, labels)
  end

  def render(args, sprites, labels)
    args.outputs.sprites << sprites
    args.outputs.labels << labels
  end
end

$game ||= Game.new
def tick(args)
  $game.tick(args)
end
```

> `Class Game ... end` declares our `Game` class. In this particular case this is a class we will 'instantiate' (create an Object of type `Game`) by calling `.new` in `main.rb`. We then call it's `tick` method from further in `main`, letting us make the `Game` class instance the core for all of our game logic.

> At the start of tick we create two arrays - sprites and labels for now (there are others primitives like `borders`, `lines`, etc in GTK, but we won't be using them for now), then pass these to the `render` method, which 'shifts' (`<<`) our sprites and labels into the `args.outputs`

This is a very basic framework for the game to handle all of the other game logic we're going to create. You can run it now, but it won't do anything. We'll get to that when we add the first pieces of our framework. Give it a try from the DragonRuby directory with:
```
./dragonruby ascii
```

## Controllers
First up, to make sure we're laying a framework we can expand, I like to use a range of separate 'controllers' depending on where we are in the game lifecycle - title screen, in game, post-game, pause menu, etc. So the first thing I want us to add is a title screen/controller.

Create a new folder at `/app/controllers`.

Create a new file at `/app/controllers/title_controller.rb`, and fill it with the code below. For _these_ controllers we will be using them as Classes, rather than _instances_ of classes as the intention is to use use the args.state to manage all of the game state.

> Ruby Classes have 'class methods' and 'instance methods'. Instance methods operate on an object, and are typically used to update its variables, or perform actions specific to the object. Class methods don't operate on the object, but can perhaps take input, process it and produce an output.

So their tick and render functions will be class methods `self.tick` and `self.render`
```ruby
# /ascii/app/controllers/title_controller.rb
module Controllers
  class TitleController
    def self.tick(args)
    end

    def self.render(state, sprites, labels)
    end
  end
end
```

> the `Module` keyword lets you 'namespace' your code. Namespacing in a module like this can be used to, for example, encapsulate a bunch of useful code into a single library - making it easier to re-use code in other projects - or, in this case, just to namespace core 'concepts', such as Controllers, Entities (players, enemies, etc), and other things.

Now go into `main.rb` and make sure to include this file (some people like to create a `require.rb` file in the root of the project, and require all of the files from there, meaning you just need to `require 'app/require.rb'` in  `main.rb`):
```ruby
# /ascii/app/main.rb
require 'app/controllers/title_controller.rb'
# ... etc
```

> In ruby, we include the code from other files by using the `require` keyword. In GTK, it is necessary that all files other than `main.rb` are "required" at the top of `main.rb`. We're using a relative path here, relative to the 'root' of the Project folder.

> We're assigning a global variable `$game` using the ruby "double pipe"/"or equals". This basically says "get the value of $game, but if it's not already set, set it to `Game.new`". It's a way of executing the `new` code only once to assign the value, thereafter we'll grab the already assigned value (in this case an instance of "Game").

We then need to add a means of tracking the currently active controller. Within `main.rb`, add the following:

```ruby
# /ascii/app/main.rb
class Game
  attr_reader :active_controller

  def goto_title
    @active_controller = ::Controllers::TitleController
  end

  # The existing code is here
end
```

> the `attr_reader` keyword sets `active_controller` as a "Getable" attribute on the Controller. This means that any code in the project can ask an instance of `Game` what its `active_controller` is via `game.active_controller`, and it will return the value. Using `attr_reader` makes it only a 'getter' - so other code can ask what the value is, but cannot set it. Only the Game instance itself can set the value via `@active_controller = ...`

Within the `Game#tick` method, add this as the first line:
```ruby
# /ascii/app/main.rb#tick
goto_title unless active_controller
```

> `unless` is a nice example of Ruby's dedication to producing readable code. It is basically the opposite of an `if` statement, lets you avoid things like `if !true`, to instead say `do this, unless some condition is true`. In this case we're saying "call to `goto_title` method unless we already have an active controller"

After the `labels = []` add this, right before the render call:
```ruby
# /ascii/app/main.rb#tick
active_controller.tick(args)
active_controller.render(args.state, sprites, labels)
```
It may not look like much, but the active controller is now being set and its tick/render methods being called. Next up we need to get the active controller to do something with these methods.

## The First Output - Labels
Within the `title_controller.rb`, in the render method add the following lines:
```ruby
# /ascii/app/controllers/title_controller.rb#render
labels << [640, 500, 'ASCII']
labels << [640, 400, 'Press space to start']
```
Give the game a run from the command line, and we'll take a look at the "Hot Reloading" feature of GTK. With the game running, change these values to:
```ruby
# /ascii/app/controllers/title_controller.rb#render
labels << [620, 300, 'ASCII']
labels << [550, 100, 'Press space to start']
```
>Hot Reloading lets you make changes to your code while your project is running, letting you instantly see the result of those changes.

They're sitting about central now, and looking a bit like a title screen. We need a neat graphic though.

## The Second Output - Sprites
Create a new folder in `/app/sprites` and copy the `dragonruby.png` file from the GTK distribution into that directory.

Within the `TitleController`'s `render` method, add the following:
```ruby
# /ascii/app/controllers/title_controller.rb#render
sprites << [576, 500, 128, 101, 'dragonruby.png']
```

Run the game again, and you should see a nice title screen with text and a sprite.

## Input
We want to actually launch the game when space is pressed, but to do that we need a couple of things: 1) we need a 'GameController', and 2) we need to handle some keyboard input. Let's start with the controller.

Create a new file at `./app/controllers/game_controller.rb`, and fill in this skeleton code, similar to when we created the TitleController, except we hav a `reset` method in here this time to allow the game to reset anything it needs to within the `$args.state`:
```ruby
# /ascii/app/controllers/game_controller.rb
module Controllers
  class GameController
    def self.tick(args)
    end

    def self.render(state, sprites, labels)
    end

    def self.reset(state)
    end
  end
end
```
And again go into `main.rb` and make sure to include this file:

```ruby
# /ascii/app/main.rb
require 'app/controllers/title_controller.rb'
require 'app/controllers/game_controller.rb'
# ... etc
```

Within the `Game` class, add a new method, `goto_game`:
```ruby
# /ascii/app/main.rb
def goto_game(args)
  ::Controllers::GameController.reset(args.state)
  @active_controller = ::Controllers::GameController
end
```

The `reset` method wont do anything just yet, but soon it will be padded out to make sure that the game data is in a 'known good' state before the game portion runs.

The `GameController` is ready to take action now, so we need to switch to it. This is done by watching for an input within the `TitleController`'s `tick` method. So, change it to:
```ruby
# /ascii/app/controllers/title_controller.rb
def self.tick(args)
  $game.goto_game(args) if args.inputs.keyboard.space
end
```
This is a good stopping point - we have some label and sprite rendering, and the game is transitioning between controllers based on a state.

Example code is available in the `ascii` folder.
