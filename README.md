# Umbra

Create ncurses applications using a simple small library.
The source is small and simple, so easy to hack if need be. 
This is a stripped version of `canis` gem (ncurses ruby). 

 - Minimal functionality
 - Very close to ncurses, should not try to wrap everything
 - load only what you need
 - not necessarily object oriented, that is not a goal
 - should be able to use a file or widget from here (in another application) without having to copy too much
 - should be able to understand one file without having to understand entire library
 - should be easy for others to change as per their needs, or copy parts.


## Gem name
  The name `umbra` was taken, so had to change the gem name to `ncumbra` but the packages and structure etc remain umbra.

## Motivation for yet another ncurses library

 `rbcurse` and `canis` are very large. Too many dependencies on other parts of system. This aims to be small and minimal, 
 keeping parts as independent as possible. 

## Future versions
 - Ampersand in Label and Button to signify shortcut/mnemonic.
 - table (0.1.1 has it)
 - combo list
 - 256 colors
 - tree (maybe)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ncumbra'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ncumbra

## Verify your install

To save time, it is recommended that you verify that the pre-requisites are working fine.

1. Installing this gem, should have installed the dependency `ffi-ncurses`. First, go to the examples directory of `ffi-ncurses` and run the sample programs. If all if fine, then you have a proper ncurses and ffi-ncurses installation.

If this step fails, you may have to either install ffi-ncurses manually:

    gem install ffi-ncurses

or you may not have ncurses installed:

    brew install ncurses

2. Now check that the samples in the `examples` directory are working fine. You can run:

      ruby examples/ex1.rb


     ruby examples/ex2.rb

  If these are running fine, then you have a working copy of `umbra`. The `examples` folder has working examples of labels, fields, listboxes, textboxes and table. There is also a `tut` folder that has simple examples that are shown below.

## Usage

### Printing Hello World in a window

```ruby
require 'umbra'

## Basic hello world program

begin
  include Umbra
  init_curses
  win = Window.new
  win.printstring(10,10, "Hello World!");
  win.wrefresh

  win.getchar

ensure
  win.destroy
  FFI::NCurses.endwin
end
```

Following is a brief explanation of the lines above.

The `require umbra` is required to include some minimal functionality.

`include Umbra` is not required, but makes the samples easier to type  so that one does not need to prepend objects with `Umbra::`

`init_curses` - sets up the ncurses environment. Please check the examples in case the name has changed by the final version.

`win = Window.new` - creates a root window. Since no dimensions are specified, a full-screen window is created.

Dimension  may be specified as follows:

        win = Window.new _height, _width, _top, _left

When windows are created in this manner, it is essential to call `window.destroy` in the ensure block of the program.
One may also use the block style of creating a window as follows:

```ruby
   Window.create 0,0,0,0 do |win|
       win.printstring 0,0, "Hello World"
       win.getchar
   end
```

This takes care of destroying the window at the end of the block.

Although ncurses provides methods for moving the cursor to a location, and printing at that location, there is a convenience method for doing the same.

    win.printstring( row, column, string, color_pair, attribute).

In order to pause the screen, the program pauses to accept a keystroke.

    win.getchar

Right now we are not interesting in evaluating the key, we just want the display to pause. Press a key and the window will clear, and you will return to the prompt, and your screen should be clear. In this simple program, we avoided checking for exceptions, which will be included in programs later.

The `getchar` method waits for a keystroke. Usually, the examples use `getkey` (aka `getch`) which does not pause for a keystroke.
Try replacing `getchar` with `getch` and run the program. The program closes after a second when `getch` returned a `-1`. This has been used so that forms can have continuous updates without waiting for a keystroke.



One can create color pairs or used some of the pre-created ones from `init_curses` in `window.rb`.

    win.printstring( 1, 10, "Hello Ruby", CP_YELLOW, REVERSE).


### Important Window methods:

-   `Window.new`
-   `Window.new 0,0, 80, 20`
-   `Window.create(h, w, top, left) {|win| .... }`
-   `win.destroy`
-   `win.printstring(row, col, string, color_pair, attribute)`
-   `win.wrefresh`
-   `win.box`
-   `win.getch` (alias getkey)
-   `win.getchar` (waits for keystroke)

In later examples, we will not print using the `window.printstring` method, but will instead create a `label`.

### Creating a Form

In order to create a user-interface we need to create a `Form` object. A form manages various widgets or controls such as labels, entry fields, lists, boxes, tables etc. It manages traversal and printing of the same. It handles events. Widgets created must be associated with a form, for them to be operational.

```ruby
form = Form.new win
form.add_widget title
```

The above block creates a `Form` passing a window object. This is required as the Form will use the window for display. This gem does NOT write onto `stdscr`, all writes go to a window.
A widget is then added to the Form so it can be displayed. Before we create a widget let us visit the important methods of a Form object:

- `add_widget` (or `add`) used to register a widget with the form. May take a comma-separated list of widgets.
- `remove_widget` - remove given widget (rarely used)
- `pack` - this method is to be called after creating all the widgets before the screen is to be painted.  IT carries out various functions such as registering shortcuts/hotkeys, creating a list of focusable objects, and laying out objects (layout are in a future version).
- `repaint` - paints all the registered widgets. In most cases, dimensions are calculated at the time or painting and not at creation time. Note that widgets are only repainted if changed. This minimizes processing and painting.
- `handle_key(ch)` - the form handles the key for traversal or hands it to the currently focussed field. This is the key that was received by the `window.getkey` method.

There are other form methods that one may or may not use such as `select_first_field`, `select_next_field`, `current_widget` (find out which widget is focussed), put focus on a widget (`select_field` aka `focussed_widget`)

At the time of writing (v 0.1.1), `pack` no longer calls `repaint`. It may do so in the future, if found to always happen.

### Creating a Label

The simplest widget in `Umbra` is the Label. Labels are used for a single line of text . The `text` of a label specifies the text to display. Other methods of a label are row, col, width and justify (alignment). Width is important for clearing space, and for right and center alignment.

    title = Label.new( :text => "Demo of Labels", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1,
                    :justify => :center, :color_pair => 0)

A `mnemonic` and related widget may be associated with a label. This `mnemonic` is a shortcut or hotkey for jumping directly to another which is specified by `related_widget`. The `related_widget` must be a focusable object such as a `Field` or `Listbox`. The `mnemonic` is displayed with bold and underlined attribute since underline may not work on some terminals. The Alt-<key> is to be pressed to jump directly to the field.

```ruby
    title.mnemonic = "t"
    title.related_widget = name
```

Modify the previous example and create a label as above. Create a `Form` and use `add_widget` to associate the two.
The `width` has been specified as the size of the current screen. You may use a value such as `20` or `40`. Stretch the window to increase the width. What happpens ?

Now change the `width` to `-1`. Run the program again and stretch the window's width. What happens ? Negative widths and heights are re-calculated at the time of printing, so a change in width of the screen will immediately reflect in the label's width. A negative value for width or height means that the object must stretch or extend to that row or column.

 See examples directory for code samples.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mare-imbrium/umbra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
