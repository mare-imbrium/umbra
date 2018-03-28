# ----------------------------------------------------------------------------- #
#         File: dialog.rb
#  Description: A simple dialog box that only depends on window.
#        This does not have forms or buttons, fields etc. That would introduce a circular
#        dependence that I would like to avoid. This way widgets can include this to print an error
#        or other message.
#        NOTE: to check similar behavior, load "links" and press "q", its displays a dialog box with yes/no.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-27 - 12:09
#      License: MIT
#  Last update: 2018-03-28 13:05
# ----------------------------------------------------------------------------- #
#  dialog.rb  Copyright (C) 2012-2018 j kepler
#
require './window.rb'
class Dialog

  attr_accessor  :text                       # text or message to print centered
  attr_accessor  :title                      # title of dialog
  attr_accessor  :title_color_pair           # color pair of title
  attr_accessor  :title_attr                 # attribute of title
  attr_accessor  :border_color_pair          # color pair of border
  attr_accessor  :border_attr                # attribute of border

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
    @title ||= "Alert"
  end

  private def variable_set var, val
    send("#{var}=", val) 
  end
  private def _create_window
    text = @text || "DID not get text"
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
    button = "[ Ok ]"
    brow   = 6
    bcol   = (w-button.size)/2
    @button_color ||= create_color_pair(COLOR_WHITE, COLOR_BLUE)
    @button_attr  ||= REVERSE
    win.printstring brow, bcol, button, @button_color, @button_attr
    FFI::NCurses.wmove(win.pointer, brow, bcol+2)
    ## ---- button section ---- }}}
    @window = win
    win.wrefresh
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
    begin
      while (ch = win.getkey) != FFI::NCurses::KEY_RETURN
        begin
          break if ch == 32 or key(?q) == ch
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
    return ch
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
    m = Dialog.new text: ARGV[0], title: ARGV[1]||"Alert"
    ch = m.run
  ensure
    FFI::NCurses.endwin 
  end
  puts "got key: #{ch}"
end
