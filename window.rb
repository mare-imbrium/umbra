require 'ffi-ncurses'
require 'ffi-ncurses/widechars'
# this pollutes the space so avoid
#include FFI::NCurses

def init_curses
  FFI::NCurses.initscr
  FFI::NCurses.curs_set 0
  FFI::NCurses.raw
  FFI::NCurses.noecho
  FFI::NCurses.keypad FFI::NCurses.stdscr, true
  FFI::NCurses.scrollok FFI::NCurses.stdscr, true
end
## window class {{{
class Window 
  attr_reader :window
  attr_reader :width, :height, :top, :left
  def initialize h=0, w=0, top=0, left=0
    @height, @width, @top, @left = h, w, top, left
    @window = FFI::NCurses.newwin(@height, @width, @top, @left) # added FFI 2011-09-6 
    #@panel = Ncurses::Panel.new(@window) # added FFI 2011-09-6 
    @panel = FFI::NCurses.new_panel(@window)
    return @window
  end
  # this is the window pointer in FFI
  def getwin
    @window
  end
  # print string. replace this with the original one 
  def printstr(str, x=0,y=0)
    win = @window
    FFI::NCurses.wmove(win, x, y)
    FFI::NCurses.waddstr win, str
  end
  def getkey 
    ch = getch
  end
  def wrefresh
    FFI::NCurses.wrefresh(@window)
  end
  def destroy
    FFI::NCurses.delwin(@window)
  end
  # route other methods to ffi
  def method_missing(name, *args)
    name = name.to_s
    if (name[0,2] == "mv")
      test_name = name.dup
      test_name[2,0] = "w" # insert "w" after"mv"
      if (FFI::NCurses.respond_to?(test_name))
        return FFI::NCurses.send(test_name, @window, *args)
      end
    end
    test_name = "w" + name
    if (FFI::NCurses.respond_to?(test_name))
      return FFI::NCurses.send(test_name, @window, *args)
    end
    FFI::NCurses.send(name, @window, *args)
  end

end # window }}}
