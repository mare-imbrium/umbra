=begin
  * Name: PadReader.rb
  * Description : This is an independent file viewer that uses a Pad and traps keys
  * Author:  jkepler
  * Date:    2018-03-28 14:30
  * License: MIT
  * Last update:  2018-03-28 16:39

  == CHANGES
  == TODO 
  - Ideally, don't even rely upon window.rb
  - title
  - currently, takes file, should take array also
  NOTE:
  in this the cursor does not move down, it starts to scroll straight away.
  So we need another version for lists and textviews in which the cursor moves with up and down.
  The cursor should be invisible in this.
  == -----------------------
=end
require 'ffi-ncurses'
require './window.rb'

class Integer
  def ifzero v
    return self if self != 0
    return v
  end
end

class Pad

  # You may pass height, width, row and col for creating a window otherwise a fullscreen window
  # will be created. If you pass a window from caller then that window will be used.
  # Some keys are trapped, jkhl space, pgup, pgdown, end, home, t b
  # This is currently very minimal and was created to get me started to integrating
  # pads into other classes such as textview.
  def initialize config={}, &block

    @config = config
    @rows = FFI::NCurses.LINES-1
    @cols = FFI::NCurses.COLS-1
    @prow = @pcol = 0
    @startrow = 0
    @startcol = 0
    
    h = config.fetch(:height, 0)
    w = config.fetch(:width, 0)
    t = config.fetch(:row, 0)
    l = config.fetch(:col, 0)
    @rows = h unless h == 0
    @cols = w unless w == 0
    @startrow = t unless t == 0
    @startcol = l unless l == 0
    @suppress_border = config[:suppress_border]
    unless @suppress_border
      @startrow += 1
      @startcol += 1
      @rows -=3  # 3 is since print_border_only reduces one from width, to check whether this is correct
      @cols -=3
    end
    @top = t
    @left = l
    view_file config[:filename]
    @window = Window.new(h, w, t, l)
    @window.box # 2018-03-28 - 
    FFI::NCurses.wbkgd(@window.pointer, FFI::NCurses.COLOR_PAIR(0));

    FFI::NCurses.curs_set 0                  # cursor invisible
    @ph = @content_rows
    @pw = @content_cols # get max col
    @pad = FFI::NCurses.newpad(@ph, @pw)

    FFI::NCurses.update_panels
    @content.each_index { |ix|

      FFI::NCurses.mvwaddstr(@pad,ix, 0, @content[ix])
    }
    @window.wrefresh
    padrefresh

    FFI::NCurses.keypad(@pad, true);         # function and arrow keys
  end

  private
  def view_file(filename)
    @file = filename
    @content = File.open(filename,"r").read.split("\n")
    @content_rows = @content.count
    @content_cols = content_cols()
  end

  # write pad onto window
  private
  def padrefresh
    FFI::NCurses.prefresh(@pad,@prow,@pcol, @startrow,@startcol, @rows + @startrow,@cols+@startcol);
  end

  # returns button index
  # Call this after instantiating the window
  public
  def run
    return handle_keys
  end

  # convenience method
  private
  def key x
    x.getbyte(0)
  end
  def content_cols
    longest = @content.max_by(&:length)
    longest.length
  end

  # returns button index
  private
  def handle_keys
    ht = @window.height.ifzero FFI::NCurses.LINES-1
    buttonindex = catch(:close) do 
      @maxrow = @content_rows - @rows
      @maxcol = @content_cols - @cols 
      while((ch = @window.getch()) != FFI::NCurses::KEY_F10 )
        #while((ch = FFI::NCurses.wgetch(@pad)) != FFI::NCurses::KEY_F10 )
        break if ch == ?\C-q.getbyte(0) 
        begin
          case ch
          when key(?g), 279 # home as per iterm2
            @prow = 0
            @pcol = 0
          when key(?b), key(?G), 277 # end as per iterm2
            @prow = @maxrow-1
            @pcol = 0
          when key(?j), FFI::NCurses::KEY_DOWN
            @prow += 1
          when key(?k), FFI::NCurses::KEY_UP
            @prow -= 1
          when 32, 338   # Page Down abd Page Up as per iTerm2
            @prow += 10
          when key(?\C-d)
            @prow += ht
          when key(?\C-b)
            @prow -= ht
          when 339
            @prow -= 10
          when key(?l), FFI::NCurses::KEY_RIGHT
            @pcol += 1
          when key(?$)
            @pcol = @maxcol - 1
          when key(?h), FFI::NCurses::KEY_LEFT
            @pcol -= 1
          when key(?0)
            @pcol = 0
          when key(?q)
            throw :close
          else 
            #alert " #{ch} not mapped "
          end
          @prow = 0 if @prow < 0
          @pcol = 0 if @pcol < 0
          if @prow > @maxrow-1
            @prow = @maxrow-1
          end
          if @pcol > @maxcol-1
            @pcol = @maxcol-1
          end
          padrefresh
          #FFI::NCurses::Panel.update_panels # 2018-03-28 - this bombs elsewhere
        rescue => err
        ensure
        end

      end # while loop
    end # close
  ensure
    @window.destroy #unless @config[:window]
    FFI::NCurses.delwin(@pad)
    return buttonindex 
  end
end
if __FILE__ == $PROGRAM_NAME
  init_curses
  begin
    h = 20
    w = 50
    p = Pad.new :filename => "pad.rb", :height => FFI::NCurses.LINES-1, :width => w, :row => 0, :col => 0
    p.run
  ensure
    FFI::NCurses.endwin
  end
end
