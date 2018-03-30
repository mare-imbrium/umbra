# ----------------------------------------------------------------------------- #
#         File: dialog.rb
#  Description: A simple dialog box that only depends on window.
#        This does not have forms or buttons, fields etc. That would introduce a circular
#        dependence that I would like to avoid. This way widgets can include this to print an error
#        or other message.
#        NOTE: to check similar behavior, load "links" and press "q", its displays a dialog box with yes/no.
#        Also check midnight-commander, press F10 to quit and see dialog box.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-27 - 12:09
#      License: MIT
#  Last update: 2018-03-30 14:49
# ----------------------------------------------------------------------------- #
#  dialog.rb  Copyright (C) 2012-2018 j kepler
#
#require './window.rb'
require 'umbra/window'

# A simple dialog box that only displays a line of text, centered.
# It can take an array of button labels (just strings) and display them, and return the index
# of the button pressed, when closed.
# If no buttons are supplied, an "Ok" button is displayed.
# Minimum requirements are `text` and `title`
class Dialog

  attr_accessor  :text                       # text or message to print centered
  attr_accessor  :title                      # title of dialog
  attr_accessor  :title_color_pair           # color pair of title
  attr_accessor  :title_attr                 # attribute of title
  attr_accessor  :border_color_pair          # color pair of border
  attr_accessor  :border_attr                # attribute of border
  attr_accessor  :buttons                    # button text array

  ## currently color and attr for text is missing. I think it should be what window has.

  def initialize config={}, &block
    config.each_pair { |k,v| variable_set(k,v) }
    if block_given?
      if block.arity > 0
        yield self
      else
        self.instance_eval(&block)
      end
    end
    @title       ||= "Alert"
    @buttons     ||= ["Ok"]
  end

  private def variable_set var, val
    send("#{var}=", val) 
  end
  private def _create_window
    text = @text || "Warning! Did not get text"
    #h = 7
    # increase height to 9 so we can put a fake button below text
    h = 9
    w = text.size + 20
    @window_color_pair ||= CP_BLACK
    @window_attr       ||= REVERSE
    win = create_centered_window h, w, @window_color_pair, @window_attr

    ## ---- border section --- {{{
    row = 1
    col = 2
    borderatt   = @border_attr || NORMAL
    bordercolor = @border_color_pair || CP_BLACK
    win.wattron(bordercolor | borderatt)
    print_border_mb win, row, col, win.height, win.width, nil, nil
    win.wattroff(bordercolor | borderatt)
    ## ---- border section --- }}}

    ## ---- title section ---- {{{
    @title            ||= "No title"
    @title_color_pair ||= CP_CYAN
    @title_attr       ||= REVERSE
    title = " "+@title+" "
    # normalcolor gives a white on black stark title like links and elinks
    # You can also do 'acolor' to give you a sober title that does not take attention away, like mc
    win.printstring(row=1,col=(w-title.length)/2,title, color=@title_color_pair, @title_attr)
    ## ---- title section ---- }}}

    win.printstring 3,(w-text.size)/2, text
    ## ---- button section ---- {{{
    paint_buttons win, @buttons, 0
    ## ---- button section ---- }}}
    @window = win
    win.wrefresh
  end
  def paint_buttons win, buttons, active_index
    brow   = 6
    bcol   = (win.width-(buttons.size*10))/2
    origbcol = bcol
    FFI::NCurses.mvwhline(win.pointer, brow-1, 3, FFI::NCurses::ACS_HLINE, win.width-6)
    #@button_color ||= create_color_pair(COLOR_BLACK, COLOR_MAGENTA)
    @button_color ||= CP_BLACK
    active_color = create_color_pair(COLOR_BLACK, COLOR_MAGENTA)
    #active_color = create_color_pair(COLOR_MAGENTA, COLOR_BLACK)
    active_col = bcol
    buttons.each_with_index do |button, ix|
      button_attr  = NORMAL
      button_color = @button_color
      _button = "[ #{button} ]"
      if ix == active_index
        button_attr = BOLD
        button_color = active_color
        active_col = bcol
        _button = "> #{button} <"
      end
      win.printstring brow, bcol, _button, button_color, button_attr
      bcol += 10
    end
    FFI::NCurses.wmove(win.pointer, brow, active_col+2)
  end

  # convenience func to get int value of a key {{{
  # added 2014-05-05
  # instead of ?\C-a.getbyte(0)
  # use key(?\C-a)
  # or key(?a) or key(?\M-x)
  def key ch
    ch.getbyte(0)
  end # }}}
  def run
   _create_window unless @window 
    win = @window
    buttoncount = @buttons.count
    buttonindex = 0
    begin
      while (ch = win.getkey) != FFI::NCurses::KEY_RETURN
        begin
          break if ch == 32 or key(?q) == ch
          # go to next button if right or down or TAB pressed
          if ch == FFI::NCurses::KEY_TAB or ch == FFI::NCurses::KEY_RIGHT or FFI::NCurses::KEY_DOWN
            buttonindex += 1
          elsif ch == FFI::NCurses::KEY_LEFT or FFI::NCurses::KEY_UP
            buttonindex -= 1
          else
            # should check against first char of buttons TODO
            #puts "Don't know #{ch}"
          end
          buttonindex = 0 if buttonindex > buttoncount-1
          buttonindex = buttoncount-1 if buttonindex < 0
          paint_buttons win, @buttons, buttonindex
        rescue => e
          puts e
          puts e.backtrace.join("\n")
        end
        win.wrefresh
      end
    ensure
      win.destroy
    end
    #FFI::NCurses.endwin # don't think this should be here if popped up by another window
    return buttonindex
  end

  # create a centered window. # {{{
  # NOTE: this should probably go into window class, or some util class.
  # TODO: it hardcodes background color. fix this.
  def create_centered_window height, width, color_pair=0, attrib=REVERSE
    row = ((FFI::NCurses.LINES-height)/2).floor
    col = ((FFI::NCurses.COLS-width)/2).floor
    win = Window.new  height, width, row, col
    #FFI::NCurses.wbkgd(win.pointer, FFI::NCurses.COLOR_PAIR(0) | REVERSE); #  does not work on xterm-256color
    FFI::NCurses.wbkgd(win.pointer, color_pair | attrib)
    return win
  end # }}}
  private def print_border_mb window, row, col, height, width, color, attr # {{{
    win = window.pointer
    #att = attr
    len = width
    len = FFI::NCurses.COLS if len == 0
    space_char = " ".codepoints.first
    (row-1).upto(row+height-1) do |r|
      # this loop clears the screen, printing spaces does not work since ncurses does not do anything
      FFI::NCurses.mvwhline(win, r, col, space_char, len)
    end

    FFI::NCurses.mvwaddch win, row, col, FFI::NCurses::ACS_ULCORNER
    FFI::NCurses.mvwhline( win, row, col+1, FFI::NCurses::ACS_HLINE, width-6)
    FFI::NCurses.mvwaddch win, row, col+width-5, FFI::NCurses::ACS_URCORNER
    FFI::NCurses.mvwvline( win, row+1, col, FFI::NCurses::ACS_VLINE, height-4)

    FFI::NCurses.mvwaddch win, row+height-3, col, FFI::NCurses::ACS_LLCORNER
    FFI::NCurses.mvwhline(win, row+height-3, col+1, FFI::NCurses::ACS_HLINE, width-6)
    FFI::NCurses.mvwaddch win, row+height-3, col+width-5, FFI::NCurses::ACS_LRCORNER
    FFI::NCurses.mvwvline( win, row+1, col+width-5, FFI::NCurses::ACS_VLINE, height-4)
  end # }}}
end

if __FILE__ == $0
  ch = nil
  begin
    init_curses
    m = Dialog.new text: ARGV[0], title: ARGV[1]||"Alert", buttons: ["Yes", "No"]
    ch = m.run
  ensure
    FFI::NCurses.endwin 
  end
  puts "got key: #{ch}"
end
