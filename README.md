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
 - many portions of `Widget` and `Form` have been rewritten and simplified.

Documentation is at: https://www.rubydoc.info/gems/ncumbra

## Gem name

  The name `umbra` was taken, so had to change the gem name to `ncumbra` but the packages and structure etc remain umbra.

## Motivation for yet another ncurses library

 `rbcurse` and `canis` are very large. Too many dependencies on other parts of system. This aims to be small and minimal,
 keeping parts as independent as possible.

## Future versions

 - Ampersand in Label and Button to signify shortcut/mnemonic.
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

2. Now check that the samples in Umbra's `examples` directory are working fine. You can run:

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
- `pack` - this method is to be called after creating all the widgets before the screen is to be painted.  It carries out various functions such as registering shortcuts/hotkeys, creating a list of focusable objects, and laying out objects (layout are in a future version).
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

Its properties include:

- `text` - text related to a button, field, label, textbox, etc. May be changed at any time, and will immediately reflect
- `row`  - vertical position on screen (0 to FFI::NCurses.LINES-1). Can be negative for relative position.
- `col`  - horizontal position on screen (0 to FFI::NCurses.COLS-1)
- `width` - defaults to length of `text` but can be larger or smaller. Can be negative.
- `height` - Height of multiline widgets or boxes. Can be negative.
- `color_pair` - Combination of foreground and background color. see details for creating colors.
- `attr` : visual attribute of text in widget. Can be `BOLD` , `NORMAL` , `REVERSE` or `UNDERLINE`
- `highlight_color_pair` - color pair to use when the widget gets focus
- `highlight_attr` - attribute to use when the widget gets focus
- `focusable` - whether the widget may take focus.
- `visible` - whether the widget is visible.
- `state` - :NORMAL or :HIGHLIGHTED. Highlighted refers to focussed.

If `row` is negative, then the position will be recalculated whenever the window is resized. Similarly, if `width` and `height` are negative, then the width is stretched to the end of the window. If the window is resized, this will be recalculated. This enables some simple resizing and placing of screen components. For complex resizing and repositioning, the Form's `:RESIZE` event should be used.

#### attr_property

  This is a variation of `attr_accessor`. It refers to attributes of an object that should result in the object being repainted, when the attribute is changed. However, whenever such attributes are modified, a `:PROPERTY_CHANGE` event is also fired, so that processing can be attached to such changes.

### Creating a Label

The simplest widget in `Umbra` is the Label. Labels are used for a single line of text . The `text` of a label specifies the text to display. Other methods of a label are row, col, width and justify (alignment). Width is important for clearing space, and for right and center alignment.

    title = Label.new( :text => "Demo of Labels", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1,
                    :justify => :center, :color_pair => 0)

The next example prints a label on the last line stretching from left to right. It will be used in later examples for printing a message when some event is triggered.

    message_label = Label.new row: -1, col: 0, width: -1, color_pair: CP_CYAN, text: "Messages will come here..."


A `mnemonic` and related widget may be associated with a label. This `mnemonic` is a shortcut or hotkey for jumping directly to another which is specified by `related_widget`. The `related_widget` must be a focusable object such as a `Field` or `Listbox`. The `mnemonic` is displayed with bold and underlined attribute since underline may not work on some terminals. The Alt-key is to be pressed to jump directly to the field.

```ruby
    title.mnemonic = "n"
    title.related_widget = name
```

Modify the previous example and create a label as above. Create a `Form` and use `add_widget` to associate the two.
The `width` has been specified as the size of the current screen. You may use a value such as `20` or `40`. Stretch the window to increase the width. What happens ?

Now change the `width` to `-1`. Run the program again and stretch the window's width. What happens ? Negative widths and heights are re-calculated at the time of printing, so a change in width of the screen will immediately reflect in the label's width. A negative value for width or height means that the object must stretch or extend to that row or column from the end. Negative widths are thus relative to the right end of the window. Positive widths are absolute.

The important properties of `Label` are:

- `text` - may be changed at any time, and will immediately reflect
- `row`  - vertical position on screen (0 to FFI::NCurses.LINES-1). Can be negative for relative position.
- `col`  - horizontal position on screen (0 to FFI::NCurses.COLS-1)
- `width` - defaults to length of `text` but can be larger or smaller. Can be negative.
- `color_pair` - see details for creating colors. e.g. `CP_GREEN` `CP_CYAN` `CP_MAGENTA`, etc.
- `attr` : maybe `BOLD` , `NORMAL` , `REVERSE` or `UNDERLINE`
- `justify` - `:right`, `:left` or `:center`
- `related_widget` - editable or focusable widget associated with this label.
- `mnemonic` - short-cut used to shift access to `related_widget`

Label also has the following method/s:

- `print_label` - override the usual printing of a label. A label usually prints in one colour and attribute (or combination of attributes). However, for any customized printing of a label, one can override this method at the instance level. For an example of customized printing, see examples/extab3.rb.

### Field

This is an entry field. Text may be edited in a `Field`. Various validations are possible. Custom validations may be specified.

```ruby
    w = Field.new( name: "name", row: 1, col: 1, width: 50)
    w.color_pair = CP_CYAN
    w.attr = FFI::NCurses::A_REVERSE
    w.highlight_color_pair = CP_YELLOW
    w.highlight_attr = REVERSE
    w.null_allowed = true
```

The above example shows creation of an editable field. The field has been further customized to have a different color when it is in focus (highlighted).


Other examples of customizations of field are as follows:
```ruby
  w.chars_allowed = /[\w\+\.\@]/
  email.valid_regex = /\w+\@\w+\.\w+/
  age.valid_range = (18..100)
  w.type = :integer
  comment.maxlen = 100
```
Validations are executed when the user exits a field, and a failed validation will throw a `FieldValidationException`
A custom validation can be given as a block to the `:CHANGED` event. More about this in events.

Field (like all focusable widgets) has events such as `:ON_LEAVE` `ON_ENTER` `:CHANGED` . Field also has an event`:CHANGE`.
- `:CHANGE` is called for each character inserted or removed from the buffer. This allows for processing to be attached to each character entered in the field.
- `:CHANGED` is called upon leaving the field, if the contents were changed.
- `:PROPERTY_CHANGE` - all widgets have certain properties which when changed result in immediate redrawing of the widget. At the same time, a program may attach processing to that change. A property may be disallowed to change by throwing a `PropertyVetoException`.

Some methods of `Field` are:

- `text` (or `default`) for setting starting value of field.
- `maxlen` - maximum length allowed during entry
- `values` - list of valid values
- `valid_range` - valid numeric range
- `valid_regex` - valid regular expression for text entered
- `above` - lower limit for numeric value (value should be above this)
- `below` - upper limit for numeric value (value should be below this)
- `mask`  - character to show for each character entered (useful for password entry)
- `null_allowed` - true or false. Can field be left blank.
- `type`  - specify what characters may be entered in the field. Can be:
     :integer, :float, :alpha, :alnum, Float, Integer, Numeric. A regexp may also be passed in.

> ##### Exercise
>
>Make a program with a label and a field. Do not add any validations or ranges to it. Get it to work.
>
>Try various validations on it. At the time of writing this (0.1.1) on_leave is not triggered as there is only one field. FIXME. So make a second field. What happens when you enter data that fails the validation ?
>
>Add a `rescue` block after the `form.handle_key`. How can you display the error to the user ? See umbra.rb for ways to popup the exception string.
>
>Make a second label and field. Use mnemonics and try out the hotkeys.
>
>A minimal sample is present as tut/field.rb.



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

>#### Exercise
>
>Create a form with two labeled fields.
>
>Try out different color_pairs and highlight_color_pairs and attributes for the field and label.
>
>What happens when you specify `lcol` and when you don't ?
>
>Place a label on the bottom of the screen and try printing the number of characters typed in the current field. The number must change as the user types. (Hint 1 below)
>
>Place another label on the screen and print the time on it. The time should update even when the user does not type. (Hint 2 below).
>
>
>Hint 1: Use `:CHANGE` event. It passes an object of class `InputDataEvent`. You might use `text` or `source` (returns the Field object).
>
>Hint 2: You can do this inside the key loop when ch is -1. Use the `text` method of the Label. Is is not updating ?
>You will need to call `form.repaint`.
>
>
>A minimal sample is present as tut/labfield.rb. You can also see examples/ex21.rb.


### Buttons

Button is a action related widget with a label and an action that fires when a user presses SPACE on it. The `:PRESS` event is associated with the space bar key. A button may also have a mnemonic that fires it's event from anywhere on the form.

In addition to the properties of the `Widget` superclass, button also has:

- `mnemonic`
- `surround_chars` - the characters on the two sides of the button, by default square brackets.

```ruby
  ok_butt = Button.new( :name => 'ok', :text => 'Ok', :row => 2, :col => 10, :width => 10 ,
  :color_pair => 0, :mnemonic => 'O')
```

> ##### Exercise
>
>Create a button with text "Cancel" which closes the window.
>Attach a code block to the Ok button to write the contents of each field to the log file and then close the window.
>
>You may see examples/ex3.rb.

`Button` is the superclass of `ToggleButton,` `RadioButton` and `Checkbox`.

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

### Checkbox

A checkbox is a button containing some text with a square on the left (or right). The square may be checked or unchecked.
Checkbox extends `ToggleButton`.


It adds the following properties to ToggleButton.

- `align_right` -  boolean, show the button on the right. Default is false.

`value` may be used to set the initial value, or retrieve the value at any time.

```ruby
    check =  Checkbox.new text: "No Frames", value: true,  row: 11, col: 10, mnemonic: "N"
    check1 = Checkbox.new text: "Use https", value: false, row: 12, col: 10, mnemonic: "U"
```

A code block may be attached to the clicking of checkboxes either using `command` or binding to `:PRESS`.
In this example, a previously created label is updated whenever the checkboxes are clicked.


```ruby
  form.add_widget check, check1
  [ check, check1 ].each do |cb|
    cb.command do
      message_label.text = "#{cb.text} is now #{cb.value}"
    end
  end
```

The above is similar to:

```ruby
   check.bind_event(:PRESS) { |cb|
      message_label.text = "#{cb.text} is now #{cb.value}"
      }
```

### RadioButton

A `ToggleButton` button that may have an on or off value. Usually, several related radio buttons are created and only one may be _on_.
Here, we create a `ButtonGroup` and then `add` radio buttons to it.

```ruby
radio1 = RadioButton.new text: "Red", value: "R", row: 5, col: 20
radio2 = RadioButton.new text: "Green", value: "G", row: 6, col: 20
group = ButtonGroup.new "Color"
group.add(radio1).add(radio2)
form.add_widget radio1, radio2
```

By default, the button prints the selector or box on the left as `( )`. By setting `align_right` the box will be printed on the right.

A block may be attached to the group which will be called if any of its buttons is clicked.


```ruby
  group.command do
    message_label.text = "#{group.name} #{group.value} has been selected"
  end
```

### ButtonGroup

A ButtonGroup is a collection of RadioButtons.

        group = ButtonGroup.new "Color"

Methods:

- `add` - add a `RadioButton` to the group.
- `selection` - return the button that is selected
- `value` - get the value of the selected button
- `select?` - ask if given button is selected
- `elements` - get an array of buttons added
- `command` - supply a block to be called whenever a button in the group is clicked.
- `select` - select the given button (simulate keypress programmatically)


```ruby
  group.command do
    alert "#{group.name} #{group.value} has been selected"
  end
```

### Multiline

Multiline is a parent class for all widgets that display multiple rows/lines and allow scrolling. It has the following attributes:

- `current_index` - get the index of row the cursor is on
- `list`   - get or set the array of String being displayed
- `row_count` - get size of array
- `current_row` - get the row having focus

Multiline allows customizing display of each row displayed by the following methods:

- `state_of_row(index)` - customize state of row based on index. One may add a new state.
- `color_of_row(index, state)` - customize color of row based on index and state. By default, the current row is highlighted whereas all other rows use NORMAL attribute.
- `value_of_row(line, index, state)` - if the array contains data other than strings (such as an Array),
             then customize how the data is to be converted to text.
- `print_row` - completely customize the printing of the row if the above are not sufficient.


Multiline exposes three events: `:ENTER_ROW`, `:LEAVE_ROW` and `:PRESS`. Press is triggered when the `RETURN` key is pressed on a row. This is not the same as selection. One may get `current_index` and `curpos` (cursor position) from the object.

A row may have one of three states.

 - :HIGHLIGHTED - the focus is inside the listbox and the cursor is on this row
 - :CURRENT     - the focus is NOT inside the listbox but the current row had focus.
 - :NORMAL      - all other rows

Only one row can have :HIGHLIGHTED or :CURRENT.


```ruby
    obj.command do |o|
       o.current_index     ## => index under cursor
       o.current_row       ## => row under cursor (converted to text)
       o.curpos            ## => position of cursor (if you want to determine word under cursor)
    end
```

Passing a code block to the `command` method is identical to attaching it to the `:PRESS` event handler.

The `:CHANGED` event is fired whenever an array is passed to the `list=` method.

#### Traversal

   In addition to arrow keys, one may use "j" and "k" for down and up. Other keys are:

   - g - first row
   - G - last row
   - C-d - scroll down
   - C-u - scroll up
   - C-b - scroll backward
   - C-f - scroll forward
   - C-a - beginning of row
   - C-e - end of row
   - C-l - scroll right
   - C-j - scroll left (C-h not working ??)
   - Spacebar - scroll forward (same as C-f)

### Listbox

Listbox is an extension of `Multiline` (parent class of all widgets that contain multiple lines of text such as listbox and tree and textbox). It displays an array of Strings, and allows scrolling. It adds the capability of selection to `Multiline`. At present, only single selection is allowed.

It adds various visual elements to `Multiline` such as a mark on the left of the item/line denoting whether an item is selected or not, and whether a item/row is current (focussed) or not. By default, a selected row displays an "x" on the left. The current row displays a greater than symbol "&gt;".

Listbox adds the following attributes to Multiline.

- `selected_index` - get index of row selected (can be nil)
- `selected_mark` - character to be displayed for selected row (default is "x")
- `unselected_mark` - character to be displayed for other rows (default blank)
- `current_mark` - character to be displayed for current row (default is "&gt;")
- `selection_key` -  key that selects current row (currently the default is "s")
- `selected_color_pair`
- `selected_attr`

Listbox adds the `:SELECT_ROW` which is fired upon selection or deselection of a row. Use `selected_index` to determine which row has been selected. A value of nil implies the current row was deselected.

```ruby
  alist = []
  (1..50).each do |i|
    alist << "#{i} entry"
  end

  lb = Listbox.new list: alist, row: 1, col: 1, width: 20, height: -2

  form.add_widget lb
```

Listbox adds the `:SELECTED` state to the existing states a row may have (:CURRENT, :HIGHLIGHTED, :NORMAL).

Listboxes allow further customization of the display of each row through the following:

- `mark_of_row(index, state)` - this returns the mark to be used for the row offset or state. Typically, this returns a single character. A `:SELECTED` row by default has an 'X' mark, a `:CURRENT` row has a '&gt;'.

Listbox adds an attribute for SELECTED rows.

Some of the methods of listboxes are:

- `list=` - supply array of values to populate listbox
- `select_row(n)` - select given row
- `unselect_row(n)` - unselect given row
- `toggle_selection` - toggle selection status of given row
- `clear_selection`  - clear selected index/es.

Inherited from Multiline:

- `current_index` - get the index of current row
- `current_row`   - get the value of current row



### Box

A Box is a container for one or more widgets. It paints a border around its periphery, and can place its components horizontally or vertically.

- `visible` - get or set visible property of border
- `title`   - title to display on top line
- `justify` - alignment of title
- `widgets` - returns array of components
- `widget`  - returns single widget if only one set

Objects are placed inside the box using either of these methods:

- `fill`    - fill the box with given widget (single)
- `stack`   - stack the given variable list of widgets horizontally (alias `add`)
- `flow`    - stack the given variable list of widgets vertically

Those who have used the `canis` gem, will recall that multiline widgets had the option of drawing their own border. This has been simplified in `umbra` by using the Box widget which does the same thing.

A box is created by giving its four coordinates.

    box = Box.new row: 4, col: 2, width: 80, height: 20

Negative width and height can be given to stretch the box to those many rows or columns from the end.
In the example below, a listbox has been created without dimensions, since the box will size it.


    lb = Listbox.new list: alist
    box.fill lb



### Textbox

Textbox extends Multiline and offers simple text display facility.

It adds `:CURSOR_MOVE` event which reports cursor movement laterally in addition to Multilines vertical movement.

Additional methods:

- `file_name(String) - name of file to load and display

Additional keystrokes:

- `w` - move to next word TODO
- `b` - move to previous word TODO

Textbox doesn't support row selection, but its always possible to use the :PRESS event as a row selection.


```ruby
    filename = "readme.md"
    box = Box.new row: 4, col: 2, width: 50, height: 20

    tb = Textbox.new file_name: filename

    box.fill tb
    box.title = filename
```
### Tabular

Tabular is a data model, not a widget. It takes an array of arrays. It can render the same as an array of strings and may thus be used to convert a database resultset to a format that may be used as input to a Textbox or even a list.

```ruby
  t = Tabular.new(['a', 'b'], [1, 2], [3, 4], [5,6])
  t.column_width(0, 3)
  t.column_align(1, :right)

  lb = Listbox.new list: t.render
  box.fill lb
```


```ruby
  t = Tabular.new ['a', 'b']
  t << [1, 2]
  t << [3, 4]
  t << [4, 6]
  t << [8, 6]
  t << [2, 6]
  lb1 = Textbox.new list: t.render
  box1.fill lb1
```

Tabular allows for customizing columns as follows:

- `column_width(n, w)` - specify width of given column
- `column_align(n, symbol)` - specify alignment of given column ( `:left` `:right` `:center` )
- `column_hidden(n, boolean)` - hide or unhide given column (true or false)
- `column_count` - returns count of visible columns
- `each_column` - yields visible columns
- `visible_columns(row)` - yields visible column data for given row
- `visible_column_names` - yields visible column names or returns array
- `add` (aliased to `add_row` and `<<`) - add a row to tabular

### Table

Table uses `Tabular` as its data model, and maintains column header and column data information. Thus, it is column-aware.

```ruby
  table = Table.new(columns: ['a', 'b'], data: [[1, 2], [3, 4], [5,6]])
  box.fill table

  table1 = Table.new columns: ['a', 'b']
  table1 << [8, 6]
  table1 << [1, 2]
  table1 << [3, 4]
  table1 << [4, 6]
```


Table may either take a pre-created Tabular object using `:tabular`, or else if will create a Tabular object from `columns` and `data` provided.

Table provides the following attributes:

- `tabular` - set a tabular object as the Table's data
- `header_color_pair`
- `header_attr`

Others:
- `data` retrieve data portion of table
- `row_count` - number of rows of data
- `current_id` - return identifier of current row (assuming first column is rowid from table)
- `current_row_as_array` - return current row as array
- `current_row_as_hash` - return current row as hash with column name as key
- `next_column` - moves cursor to next column (mapped to w)
- `prev_column` - moves cursor to previous column (mapped to b)
- `header_row?` - is cursor on header row, boolean
- `color_of_data_row(index, state, data_index)` - customize color of data row
- `color_of_header_row(index, state)` - customize color of header row
- `convert_value_to_text(current_row, format_string, index)` - customize conversion of current row to String

Table forwards several methods to its `Tabular` data model such as `add`, `<<`, `column_width`, `column_align` and `column_hidden`.

> ##### Exercise
>
>Create a window with two tables. Populate one with the output of `ls -l` and another with the process info (using the `ps` command with appropriate options).
>Create a button which refreshes the processes upon clicking.
>You may also map a key on the form level (say F5) to refresh the process info.
>
>Assign different colors to the columns of the process lister.
>Color the rows of the directory lister based on file type, or any other logic (file size).


### Colors

This library defines a few color pairs based on ncurses defaults color constants:

    CP_BLACK    = 0
    CP_RED      = 1
    CP_GREEN    = 2
    CP_YELLOW   = 3
    CP_BLUE     = 4
    CP_MAGENTA  = 5
    CP_CYAN     = 6
    CP_WHITE    = 7

These color pairs use the color mentioned as the foreground and the terminal background color as the background color.
This expects the background color to be black or very dark.

Beyond this you may create your color pairs. Usually a color pair is created in this manner.

    FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK, FFI::NCurses::CYAN)

However, there is the option to use the following method to create a color_pair.

      create_color_pair(bgcolor, fgcolor)

This will return an Integer which can be used wherever a color pair is required, such as when specifying color_pair of a widget. It will always return the same Integer for the same combination of two colors. Thus there should be no need for you to cache this.



### Event Handling

Various events for an instance of a widget may be subscribed to. A code block attached to the event will be called when the event takes place. Some of the common events are:

- `ON_ENTER`  - executed when focus enters a widget
- `ON_LEAVE`  - executed when focus leaves a widget
- `CHANGED`   - executed when the data is changed. In the case of a Field, this is when user exits after changing.
              In the case of `Multiline` widgets such as `Listbox` and `Table` this is whenever the list if changed.
- `PROPERTY_CHANGE` - executed whenever a property is changed. Properties are defined using `attr_property`. Properties such as color_pair, attr, width, title, alignment fire this event when changed _after_ the object is first displayed.
- `ENTER_ROW` - In `Multiline` widgets, whenever user enters a row.
- `LEAVE_ROW` - In `Multiline` widgets, whenever user leaves a row.

An object's `bind_event` is used to attach a code block to an event.

    field.bind_event(:CHANGED) { |f| do_some_validation(f) }

    list.bind_event(:ENTER_ROW) { |l| display some data related to current row in status line .... }


### Key Bindings

For an object, or for the form, keys may be bound to a code block. All functionality in this library is bound to a code block, making it possible to override provided behavior, although that is not recommended. Tab, backtab and Escape may not be over-ridden.

    form.bind_key(KEY_F1, "Help") { help() }

    table.bind_key(?s, "search") { search }

    list.bind_key(FFI::NCurses::KEY_CTRL_A, 'cursor home')  { cursor_home }

One may bind Control, Alt, Function and Shifted-Function keys in Umbra. However, multiple keys as in vim or emacs may not be bound. If you require mapping key combinations such as "gg" or "Ctrl-x x" then you should look at the canis gem.
You may also map the first key to a method that takes a second key. In such cases, it is better to popup a menu so the user knows that a second key is pending.

(Note: TAB and BACKTAB are hardcoded in form.rb for traversal, ESCAPE is hardcoded in field.rb. If a widget does not consume the ARROW keys, they may also be used for traversal by form.rb)

## More examples

 See examples directory for code samples for all widgets. Be sure the run all the examples to see the capabilities of the library and the widgets.

## Testing

I have not found a way of automated testing for ncurses applications. Suggestions are welcome.
My way is of manually testing which is cumbersome, and that discourages rewrites, refactoring, etc.

## Contributing

Please go through the source, and suggest improvements to the design and code.
How can we make this simpler, clearer ?

Bug reports and pull requests are welcome on GitHub at https://github.com/mare-imbrium/umbra.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
