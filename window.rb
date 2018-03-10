require 'ffi-ncurses'
require 'ffi-ncurses/widechars'

def init_curses
  FFI::NCurses.initscr
  FFI::NCurses.curs_set 1
  FFI::NCurses.raw
  FFI::NCurses.noecho
  FFI::NCurses.keypad FFI::NCurses.stdscr, true
  FFI::NCurses.scrollok FFI::NCurses.stdscr, true
  if FFI::NCurses.has_colors
    FFI::NCurses.start_color
    std_colors
  end
end

def std_colors
  FFI::NCurses.use_default_colors
  FFI::NCurses.init_pair(0,  FFI::NCurses::BLACK,   -1)
  FFI::NCurses.init_pair(1,  FFI::NCurses::WHITE,   -1)
  FFI::NCurses.init_pair(2,  FFI::NCurses::RED,     -1)
  # statusline
  FFI::NCurses.init_pair(3,  FFI::NCurses::GREEN,   -1)
  FFI::NCurses.init_pair(4,  FFI::NCurses::BLUE,    -1)
  FFI::NCurses.init_pair(5,  FFI::NCurses::YELLOW,  -1)
  FFI::NCurses.init_pair(6,  FFI::NCurses::MAGENTA, -1)
  FFI::NCurses.init_pair(7,  FFI::NCurses::CYAN,    -1)
  #FFI::NCurses.init_pair(8,  FFI::NCurses::WHITE,    -1)
  #FFI::NCurses.init_pair(9,  FFI::NCurses::BLUE,    -1)

=begin
  FFI::NCurses.init_pair(8,  FFI::NCurses::WHITE,   FFI::NCurses::BLUE)
  FFI::NCurses.init_pair(9,  FFI::NCurses::BLUE,   FFI::NCurses::BLUE)
  FFI::NCurses.init_pair(10, FFI::NCurses::BLACK,   FFI::NCurses::GREEN)
  FFI::NCurses.init_pair(11, FFI::NCurses::BLACK,   FFI::NCurses::YELLOW)
  FFI::NCurses.init_pair(12, FFI::NCurses::BLACK,   FFI::NCurses::BLUE)
  FFI::NCurses.init_pair(13, FFI::NCurses::BLACK,   FFI::NCurses::MAGENTA)
  FFI::NCurses.init_pair(14, FFI::NCurses::BLACK,   FFI::NCurses::CYAN)
  FFI::NCurses.init_pair(15, FFI::NCurses::BLACK,   FFI::NCurses::WHITE)
=end
end
#
## window class {{{
class Window 
  attr_reader :window
  attr_reader :width, :height, :top, :left
  def initialize h=0, w=0, top=0, left=0
    @height, @width, @top, @left = h, w, top, left

    @height = FFI::NCurses.LINES if @height == 0   # 2011-11-14 added since tired of checking for zero
    @width = FFI::NCurses.COLS   if @width == 0
    @window = FFI::NCurses.newwin(@height, @width, @top, @left) # added FFI 2011-09-6 

    @panel = FFI::NCurses.new_panel(@window)
    FFI::NCurses.keypad(@window, true)
    return @window
  end
  # this is the window pointer in FFI
  def getwin
    @window
  end
  # print string. replace this with the original one below
  def printstr(str, x=0,y=0)
    win = @window
    FFI::NCurses.wmove(win, x, y)
    FFI::NCurses.waddstr win, str
  end

  # 2018-03-08 - taken from canis reduced
  # r - row, c - col
  def printstring(r,c,string, color=0, att = FFI::NCurses::A_NORMAL)

    $log.debug "printstring recvd nil row #{r} or col #{c}, color:#{color},att:#{att}."  if $log
    raise "printstring recvd nil row #{r} or col #{c}, color:#{color},att:#{att} " if r.nil? || c.nil?
    att ||= FFI::NCurses::A_NORMAL
    color ||= 0
    raise "color is nil " unless color
    raise "att is nil " unless att

    FFI::NCurses.wattron(@window, FFI::NCurses.COLOR_PAIR(color) | att)
    FFI::NCurses.mvwprintw(@window, r, c, "%s", :string, string);
    FFI::NCurses.wattroff(@window, FFI::NCurses.COLOR_PAIR(color) | att)
  end
  # this will get control keys and function keys but not Alt keys
  # For alt keys we need to check for 27/Esc and if so, then do another read
  # with a timeout. If we get a key, then resolve. Otherwise, it is just ESC
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
