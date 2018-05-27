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

There are other form methods that one may or may not use such as `select_first_field`, `select_next_field`, `current_widget` (find out which widget is focussed), put focus on a widget (`select_field` aka `select_widget`)

At the time of writing (v 0.1.1), `pack` no longer calls `repaint`. It may do so in the future, if found to always happen.

Form registers only one event `:RESIZE` which is triggered when the window is resized. You may use this to recalculate widgets. For example:

    @form.bind(:RESIZE) {  resize }   ## resize is a user-defined method that recalculates positions and dimensions

#### Traversal

Traversal between focusable objects may be done using the TAB or Backtab keys. Arrow keys also work.

### Widget

Widget is the common superclass of all user-interface controls. It is never instantiated directly.

It's properties include:

- `text` - text related to a button, field, label, textbox, etc. May be changed at any time, and will immediately reflect
- `row`  - vertical position on screen (0 to FFI::NCurses.LINES-1). Can be negative for relative position.
- `col`  - horizontal position on screen (0 to FFI::NCurses.COLS-1)
- `width` - defaults to length of `text` but can be larger or smaller. Can be negative.
- `height` - Height of multiline widgets or boxes. Can be negative.
- `color_pair` - Combination of foreground and background color. see details for creating colors.
- `attr` : maybe `BOLD` , `NORMAL` , `REVERSE` or `UNDERLINE`
- `highlight_color_pair` - color pair to use when the widget gets focus
- `highlight_attr` - attribute to use when the widget gets focus
- `focusable` - whether the widget may take focus.
- `visible` - whether the widget is visible.
- `state` - :NORMAL or :HIGHLIGHTED. Highlighted refers to focussed.

If `row` is negative, then the position will be recalculated whenever the window is resized. Similarly, if `width` and `height` are negative, then the width is stretched to the end of the window. If the window is resized, this will be recalculated. This enables some simple resizing and placing of screen components. For complex resizing and repositioning the Form's `:RESIZE` event should be used.

### Creating a Label

The simplest widget in `Umbra` is the Label. Labels are used for a single line of text . The `text` of a label specifies the text to display. Other methods of a label are row, col, width and justify (alignment). Width is important for clearing space, and for right and center alignment.

    title = Label.new( :text => "Demo of Labels", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1,
                    :justify => :center, :color_pair => 0)

A `mnemonic` and related widget may be associated with a label. This `mnemonic` is a shortcut or hotkey for jumping directly to another which is specified by `related_widget`. The `related_widget` must be a focusable object such as a `Field` or `Listbox`. The `mnemonic` is displayed with bold and underlined attribute since underline may not work on some terminals. The Alt-key is to be pressed to jump directly to the field.

```ruby
    title.mnemonic = "n"
    title.related_widget = name
```

Modify the previous example and create a label as above. Create a `Form` and use `add_widget` to associate the two.
The `width` has been specified as the size of the current screen. You may use a value such as `20` or `40`. Stretch the window to increase the width. What happens ?

Now change the `width` to `-1`. Run the program again and stretch the window's width. What happens ? Negative widths and heights are re-calculated at the time of printing, so a change in width of the screen will immediately reflect in the label's width. A negative value for width or height means that the object must stretch or extend to that row or column from the end. Negative widths are thus relative to the right end of the window. Positive widths are absolute.

The important methods of `Label` are:

- `text` - may be changed at any time, and will immediately reflect
- `row`  - vertical position on screen (0 to FFI::NCurses.LINES-1). Can be negative for relative position.
- `col`  - horizontal position on screen (0 to FFI::NCurses.COLS-1)
- `width` - defaults to length of `text` but can be larger or smaller. Can be negative.
- `color_pair` - see details for creating colors.
- `attr` : maybe `BOLD` , `NORMAL` , `REVERSE` or `UNDERLINE`
- `justify` - `:right`, `:left` or `:center`
- `related_widget` - editable or focusable widget associated with this label.
- `mnemonic` - short-cut used to shift access to `related_widget`
- `print_label` - override the usual printing of a label. A label usually prints in one colour and attribute (or combination of attributes. However, for any customized printing of a label, one can override this method at the instance level.

### Field

This is an entry field. Text may be edited in a `Field`. Various validations are possible. Custom validations may be specified. 

```ruby
    w = Field.new( :name => "name", :row => 1, :col => 1 , :width => 50)
    w.color_pair = CP_CYAN
    w.attr = FFI::NCurses::A_REVERSE
    w.highlight_color_pair = CP_YELLOW
    w.highlight_attr = REVERSE
    w.null_allowed = true
```

The above example shows creation of an editable field. The field has been further customized to have a different color when it is in focus (highlighted).


Other customizations of field are as follows:
```ruby
  w.chars_allowed = /[\w\+\.\@]/
  email.valid_regex = /\w+\@\w+\.\w+/
  age.valid_range = (18..100)
  w.type = :integer
  comment.maxlen = 100
```
Validations are executed when the user exits a field, and a failed validation will throw a `FieldValidationException`
A custom validation can be given as a block to the `:CHANGED` event. More about this in events.

Field (like all focusable widgets) has events such as `:ON_LEAVE` `ON_ENTER` `:CHANGED` `:CHANGE`.
- `:CHANGE` is called for each character inserted or removed from the buffer. This allows for processing to be attached to each character entered in the field.
- `:CHANGED` is called upon leaving the field, if the contents were changed.
- `:PROPERTY_CHANGE` - all widgets have certain properties which when changed result in immediate redrawing of the widget. At the same time, a program may attach processing to that change. A property may be disallowed to change by throwing a `PropertyVetoException`.

Some methods of `Field` are:

- `text` (or `default`) for setting starting value of field.
- `maxlen` - maximum length allowed
- `values` - list of valid values
- `valid_range` - valid numeric range 
- `above` - lower limit for numeric value
- `below` - upper limit for numeric value
- `mask`  - character to show for each character entered
- `type`  - specify what characters may be entered in the field. Can be:
     :integer, :float, :alpha, :alnum, Float, Integer, Numeric. A regexp may also be passed in.

Make a program with a label and a field. Do not add any validations or ranges to it. Get it to work.

Try various validations on it. At the time of writing this (0.1.1) on_leave is not triggered as there is only one field. FIXME. So make a second field. What happens when you enter data that fails the validation ?

Add a `rescue` block after the `form.handle_key`. How can you display the error to the user ? See umbra.rb for ways to popup the exception string.

Make a second label and field. Use mnemonics and try out the hotkeys.

A minimal sample is present as tut/field.rb.



### LabeledField

A labeled field associates a label and a field. This helps in printing a label and its associated field side by side. Also, a mnemonic will automatically change focus to its related field. `LabeledField` extends Field and so has all the properties of a `Field`. In addition, it has the following:

- `label` - String to print
- `lrow` and `lcol` - labels position
- `label_color_pair`- color pair of label 
- `label_attr`     - attribute of label
- `label_highlight_color_pair`     - color pair of label when field is in focus
- `label_highlight_attr`     - attribute of label when field is in focus.
- `mnemonic` - shortcut key for moving focus to this field.




```ruby
    lf = LabeledField.new( :name => "name", :row => 1, :col => 15 , :width => 20, 
                         label: "Name: ", :label_highlight_attr => BOLD
                        )
```

Create a form with two labeled fields. 

Try out different color_pairs and highlight_color_pairs and attributes for the field and label.

What happens when you specify `lcol` and when you don't ?

Place a label on the bottom of the screen and try printing the number of characters typed in the current field. The number must change as the user types. (Hint 1 below)

Place another label on the screen and print the time on it. The time should update even when the user does not type. (Hint 2 below).


Hint 1: Use `:CHANGE` event. It passes an object of class `InputDataEvent`. You might use `text` or `source` (returns the Field object).

Hint 2: You can do this inside the key loop when ch is -1. Use the `text` method of the Label. Is is not updating ?
You will need to call `form.repaint`.


A minimal sample is present as tut/labfield.rb. You can also see examples/ex21.rb.


### Buttons

Button is a action related widget with a label and an action that fires when a user presses SPACE on it. The `:PRESS` event is associated with the space bar key. A button may also have a mnemonic that fires it's event from anywhere on the form.

In addition to the properties of the `Widget` superclass, button also has:

- `mnemonic`
- `surround_chars` - the characters on the two sides of the button, by default square brackets.

The button is the superclass of ToggleButton, RadioButton and Checkbox.

### Togglebutton

This button has an on and off state. 

- `onvalue` and `offvalue` - set the values for on and off state
- `value` - get which of onvalue and offvalue is current (boolean)
- `checked?` - returns true if onvalue, false if offvalue
- `checked` - programmatically set value to true or false


```ruby

  togglebutton = ToggleButton.new()
  togglebutton.value = true
  togglebutton.onvalue = " Toggle Down "
  togglebutton.offvalue ="  Untoggle   "
  togglebutton.row = row
  togglebutton.col = col

  togglebutton.command do
    if togglebutton.value
      message_label.text = "Toggle button was pressed"
    else
      message_label.text = "UNToggle button was pressed"
    end
  end
    
  togglebutton.checked(true)    ## simulate keypress
  togglebutton.checked?         ## => true
  togglebutton.value            ## => true

```

`Widget` the common ancestor to all user-interface controls defined a method `command`, which takes a block. That block is executed when a button is fired. For other widgets, it is fired when the `:CHANGED` event is called.

### Listbox

todo add description here



### Box

todo add description here



### Textbox

todo add description here

### Table

todo add description here


### Colors



### Event Handling

Various events for an instance of a widget may be subscribed to. A code block attached to the event will be called when the event takes place. Some of the common events are:

- `ON_ENTER`  - executed when focus enters a widget
- `ON_LEAVE`  - executed when focus leaves a widget
- `CHANGED`   - executed when the data is changed. In the case of a Field, this is when user exits after changing.
              In the case of `Multiline` widgets such as `Listbox` and `Table` this is whenever the list if changed.
- `PROPERTY_CHANGE` - executed whenever a property is changed. Properties are defined using `attr_property`.
- `ENTER_ROW` - In `Multiline` widgets, whenever user enters a row.
- `LEAVE_ROW` - In `Multiline` widgets, whenever user leaves a row.

### Key Bindings

For an object, or for the form, keys may be bound to a code block. All functionality in the system is bound to a code block, making it possible to override provided behavior, although that is not recommended. Tab, backtab and Escape may not be over-ridden.

    form.bind_key(KEY_F1, "Help") { help() }

    table.bind_key(?s, "search") { search }


 See examples directory for code samples.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/mare-imbrium/umbra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
