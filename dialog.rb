# ----------------------------------------------------------------------------- #
#         File: dialog.rb
#  Description: 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-27 - 12:09
#      License: MIT
#  Last update: 2018-03-27 23:16
# ----------------------------------------------------------------------------- #
#  dialog.rb  Copyright (C) 2012-2018 j kepler
#
require './window.rb'
class Dialog
  attr_accessor  :text
  attr_accessor  :title
  #def initialize text, title="Alert"
  def initialize config={}, &block
    config.each_pair { |k,v| variable_set(k,v) }
    #instance_eval &block if block_given?
    if block_given?
      if block.arity > 0
        yield self
      else
        self.instance_eval(&block)
      end
    end
    @title ||= "Alert"
  end

  def variable_set var, val
    send("#{var}=", val) 
  end
  def _create_window
    text = @text || "DID not get text"
    h = 7
    w = text.size + 20
    win = create_centered_window h, w
    borderatt = REVERSE
    bordercolor = 0

    row = 1
    col = 2
    win.wattron(FFI::NCurses.COLOR_PAIR(0) | (borderatt || FFI::NCurses::A_NORMAL))
    print_border_mb win, row, col, win.height, win.width, nil, nil
    win.wattroff(FFI::NCurses.COLOR_PAIR(0) | (borderatt || FFI::NCurses::A_NORMAL))

    @title ||= "No title"
    @title_color ||= CP_CYAN
    title = " "+@title+" "
    # normalcolor gives a white on black stark title like links and elinks
    # You can also do 'acolor' to give you a sober title that does not take attention away, like mc
    win.printstring(row=1,col=(w-title.length)/2,title, color=@title_color, REVERSE)

    win.printstring 3,5, text
    @window = win
    win.wrefresh
  end
  def run

   _create_window unless @window 
    win = @window
    while (ch = win.getkey) != FFI::NCurses::KEY_RETURN
      begin
        
      rescue => e
        puts e
        puts e.backtrace.join("\n")
      end
      win.wrefresh
    end
    win.destroy
    FFI::NCurses.endwin
    return ch
  end

  def create_centered_window height, width
    row = ((FFI::NCurses.LINES-height)/2).floor
    col = ((FFI::NCurses.COLS-width)/2).floor
    win = Window.new  height, width, row, col
    FFI::NCurses.wbkgd(win.pointer, FFI::NCurses.COLOR_PAIR(0) | REVERSE); #  does not work on xterm-256color
    return win
  end
  def print_border_mb window, row, col, height, width, color, attr
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
  end
end

if __FILE__ == $0
  begin
    init_curses
    m = Dialog.new text: ARGV[0], title: ARGV[1]||"Alert"
    m.run
  end
end
