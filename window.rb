require 'ffi-ncurses'
require 'ffi-ncurses/widechars'

BOLD = FFI::NCurses::A_BOLD
REVERSE = FFI::NCurses::A_REVERSE
UNDERLINE = FFI::NCurses::A_UNDERLINE
NORMAL = FFI::NCurses::A_NORMAL
COLOR_BLACK = FFI::NCurses::BLACK
COLOR_WHITE = FFI::NCurses::WHITE
COLOR_BLUE = FFI::NCurses::BLUE
COLOR_RED = FFI::NCurses::RED
COLOR_GREEN = FFI::NCurses::GREEN
COLOR_CYAN = FFI::NCurses::CYAN
COLOR_MAGENTA = FFI::NCurses::MAGENTA

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

# COLOR_BLACK   0
# COLOR_RED     1
# COLOR_GREEN   2
# COLOR_YELLOW  3
# COLOR_BLUE    4
# COLOR_MAGENTA 5
# COLOR_CYAN    6
# COLOR_WHITE   7

# In case, the init_pairs are changed, then update these as well, so that the programs use the correct pairs.
 CP_BLACK    = 0
 CP_RED      = 1
 CP_GREEN    = 2
 CP_YELLOW   = 3
 CP_BLUE     = 4
 CP_MAGENTA  = 5
 CP_CYAN     = 6
 CP_WHITE    = 7
# defining various colors
# NOTE this should be done by application or else we will be changing this all the time.
def std_colors
  FFI::NCurses.use_default_colors
  # 2018-03-17 - changing it to ncurses defaults
  FFI::NCurses.init_pair(0,  FFI::NCurses::BLACK,   -1)
  FFI::NCurses.init_pair(1,  FFI::NCurses::RED,   -1)
  FFI::NCurses.init_pair(2,  FFI::NCurses::GREEN,     -1)
  FFI::NCurses.init_pair(3,  FFI::NCurses::YELLOW,   -1)
  FFI::NCurses.init_pair(4,  FFI::NCurses::BLUE,    -1)
  FFI::NCurses.init_pair(5,  FFI::NCurses::MAGENTA,  -1)
  FFI::NCurses.init_pair(6,  FFI::NCurses::CYAN,    -1)
  FFI::NCurses.init_pair(7,  FFI::NCurses::WHITE,    -1)
  # ideally the rest should be done by application
  #FFI::NCurses.init_pair(8,  FFI::NCurses::WHITE,    -1)
  #FFI::NCurses.init_pair(9,  FFI::NCurses::BLUE,    -1)
  FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK, FFI::NCurses::CYAN)
  FFI::NCurses.init_pair(12, FFI::NCurses::BLACK,   FFI::NCurses::BLUE)
  FFI::NCurses.init_pair(13, FFI::NCurses::BLACK,   FFI::NCurses::MAGENTA)

  FFI::NCurses.init_pair(14,  FFI::NCurses::WHITE, FFI::NCurses::CYAN)
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

# create and return a color_pair for a combination of bg and fg.
# This will always return the same color_pair so a duplicate one will not be created.
# @param bgcolor [Integer] color of background e.g., COLOR_BLACK
# @param fgcolor [Integer] color of foreground e.g., COLOR_WHITE
# @return [Integer] - color_pair which can be passed to #printstring, or used directly as #COLOR_PAIR(int)
def create_color_pair(bgcolor, fgcolor)
  code = (bgcolor*10) + fgcolor
  FFI::NCurses.init_pair(code, fgcolor, bgcolor)
  return code
end
#
## Window class 
#  Creates and manages the underlying window in which we write or place a form and fields.
#  The two important methods here are the constructor, and +destroy()+.
#  +pointer+ is important for making further direct calls to FFI::NCurses.
class Window 
  # pointer to FFI routines, use when calling FFI directly.
  attr_reader :pointer     # window pointer
  attr_reader :panel      # panel associated with window
  attr_reader :width, :height, :top, :left

  # creates a window with given height, width, top and left.
  # If no args given, creates a root window (i.e. full size).
  # @param  height [Integer]
  # @param  width [Integer]
  # @param  top [Integer]
  # @param  left [Integer]
  def initialize h=0, w=0, top=0, left=0
    @height, @width, @top, @left = h, w, top, left

    @height = FFI::NCurses.LINES if @height == 0   # 2011-11-14 added since tired of checking for zero
    @width = FFI::NCurses.COLS   if @width == 0
    @pointer = FFI::NCurses.newwin(@height, @width, @top, @left) # added FFI 2011-09-6 

    @panel = FFI::NCurses.new_panel(@pointer)
    FFI::NCurses.keypad(@pointer, true)
    return @pointer
  end

  # print string at x, y coordinates. replace this with the original one below
  # @deprecated
  def printstr(str, x=0,y=0)
    win = @pointer
    FFI::NCurses.wmove(win, x, y)
    FFI::NCurses.waddstr win, str
  end

  # 2018-03-08 - taken from canis reduced
  # print given string at row, col with given color and attributes
  # @param row [Integer]  row to print on
  # @param col [Integer]  column to print on
  # @param color [Integer] color_pair created earlier
  # @param attr [Integer] any of the four FFI attributes, e.g. A_BOLD, A_REVERSE
  def printstring(r,c,string, color=0, att = FFI::NCurses::A_NORMAL)

    #$log.debug "printstring recvd nil row #{r} or col #{c}, color:#{color},att:#{att}."  if $log
    raise "printstring recvd nil row #{r} or col #{c}, color:#{color},att:#{att} " if r.nil? || c.nil?
    att ||= FFI::NCurses::A_NORMAL
    color ||= 0
    raise "color is nil " unless color
    raise "att is nil " unless att

    FFI::NCurses.wattron(@pointer, FFI::NCurses.COLOR_PAIR(color) | att)
    FFI::NCurses.mvwprintw(@pointer, r, c, "%s", :string, string);
    FFI::NCurses.wattroff(@pointer, FFI::NCurses.COLOR_PAIR(color) | att)
  end
  ##
  # Get a key from the standard input.
  #
  # This will get control keys and function keys but not Alt keys.
  # This is usually called in a loop by the main program.
  # It returns the ascii code (integer).
  # 1 is Ctrl-a .... 27 is Esc
  # FFI already has constants declared for function keys and control keys for checkin against.
  # Can return a 3 or -1 if user pressed Control-C.
  #
  # NOTE: For ALT keys we need to check for 27/Esc and if so, then do another read
  # with a timeout. If we get a key, then resolve. Otherwise, it is just ESC
  # @return [Integer] ascii code of key
  def getch
    ch = FFI::NCurses.wgetch(@pointer)
  rescue SystemExit, Interrupt 
    3      # is C-c
  rescue StandardError
    -1     # is C-c
  end
  alias :getkey :getch

  # refresh the window (wrapper)
  # To be called after printing on a window.
  def wrefresh
    FFI::NCurses.wrefresh(@pointer)
  end
  # destroy the window and the panel. 
  # This is important. It should be placed in the ensure block of caller application, so it happens.
  def destroy
    FFI::NCurses.del_panel(@panel) if @panel
    FFI::NCurses.delwin(@pointer)   if @pointer
    @panel = @pointer = nil # prevent call twice
  end
  # route other methods to ffi. {{{
  # This should preferable NOT be used. Better to use the direct call itself.
  # It attempts to route other calls to FFI::NCurses by trying to add w to the name and passing the pointer.
  # I would like to remove this at some time.
  def method_missing(name, *args)
    name = name.to_s
    if (name[0,2] == "mv")
      test_name = name.dup
      test_name[2,0] = "w" # insert "w" after"mv"
      if (FFI::NCurses.respond_to?(test_name))
        return FFI::NCurses.send(test_name, @pointer, *args)
      end
    end
    test_name = "w" + name
    if (FFI::NCurses.respond_to?(test_name))
      return FFI::NCurses.send(test_name, @pointer, *args)
    end
    FFI::NCurses.send(name, @pointer, *args)
  end # }}}
  # make a box around the window. Just a wrapper
  def box
    FFI::NCurses.box(@pointer, 0, 0)
  end
  # print a centered title on top of window
  # This should be called after box, or else box will erase the title
  # @param str [String] title to print
  # @param color [Integer] color_pair 
  # @param att [Integer] attribute constant
  def title str, color=0, att=BOLD
    strl = str.length
    col = (@width - strl)/2
    printstring(0,col, str, color, att)
  end

end # window 
