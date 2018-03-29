=begin
  * Name: PadReader.rb
  * Description : This is an independent file viewer that uses a Pad and traps keys
                  I am using only ffi-ncurses and not window.rb or any other support classes
                  so this can be used anywhere else.
  * Author:  jkepler
  * Date:    2018-03-28 14:30
  * License: MIT
  * Last update:  2018-03-29 18:50

  == CHANGES
  == TODO 
  - / search ?
  NOTE:
  in this the cursor does not move down, it starts to scroll straight away.
  So we need another version for lists and textviews in which the cursor moves with up and down.
  The cursor should be invisible in this.
  == -----------------------
=end
require 'ffi-ncurses'

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
    @height = h
    @width = w
    @pointer, @panel = create_window(h, w, t, l)
    #@window.box # 2018-03-28 - 
    FFI::NCurses.box @pointer, 0, 0
    title(config[:title])
    FFI::NCurses.wbkgd(@pointer, FFI::NCurses.COLOR_PAIR(0));
    FFI::NCurses.curs_set 0                  # cursor invisible
    if config[:filename]
      self.filename=(config[:filename])
    elsif config[:list]
      self.list=(config[:list])
    end
  end
  # minimum window creator method, not using a class.
  # However, some methods do require windows width and ht etc
  def create_window h, w, t, l
    pointer = FFI::NCurses.newwin(h, w, t, l)
    panel = FFI::NCurses.new_panel(pointer)
    FFI::NCurses.keypad(pointer, true)
    return pointer, panel
  end
  def destroy_window pointer, panel
    FFI::NCurses.del_panel(panel)  if panel
    FFI::NCurses.delwin(pointer)   if pointer
    panel = pointer = nil         # prevent call twice
  end
  def destroy_pad
    if @pad
      FFI::NCurses.delwin(@pad) 
      @pad = nil
    end
  end
  # print a title over the box on zeroth row
  def title stitle
    return unless stitle
    stitle = "| #{stitle} |"
    col = (@width-stitle.size)/2
    FFI::NCurses.mvwaddstr(@pointer, 0, col, stitle) 
  end
  private def display_content content
      @pad = create_pad content 
      FFI::NCurses.wrefresh(@pointer)
      padrefresh
  end

  private def create_pad content
    # destroy pad if exists
    destroy_pad
    @content_rows, @content_cols = content_dimensions(content)
    pad = FFI::NCurses.newpad(@content_rows, @content_cols)
    FFI::NCurses.keypad(pad, true);         # function and arrow keys

    FFI::NCurses.update_panels
    content.each_index { |ix|
      FFI::NCurses.mvwaddstr(pad,ix, 0, content[ix])
    }
    return pad
  end

  # receive array as content source
  #
  def list=(content)
    display_content content
  end
  # source of data is a filename
  def filename=(filename)
    content = File.open(filename,"r").read.split("\n")
    display_content content
  end
  private def content_dimensions content
    content_rows = content.count
    content_cols = content_cols(content)
    return content_rows, content_cols
  end


  # write pad onto window
  private
  def padrefresh
    raise "padrefresh: Pad not created" unless @pad
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
  def content_cols content
    longest = content.max_by(&:length)
    longest.length
  end

  # returns button index
  private
  def handle_keys
    @height = FFI::NCurses.LINES-1 if @height == 0
    ht = @height 
    buttonindex = catch(:close) do 
      maxrow = @content_rows - @rows
      maxcol = @content_cols - @cols 
      while ((ch = FFI::NCurses.wgetch(@pointer)) != FFI::NCurses::KEY_F10)
        break if ch == ?\C-q.getbyte(0) 
        begin
          case ch
          when key(?g), 279 # home as per iterm2
            @prow = 0
            @pcol = 0
          when key(?b), key(?G), 277 # end as per iterm2
            @prow = maxrow-1
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
            @pcol = maxcol - 1
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
          if @prow > maxrow-1
            @prow = maxrow-1
          end
          if @pcol > maxcol-1
            @pcol = maxcol-1
          end
          padrefresh
          #FFI::NCurses::Panel.update_panels # 2018-03-28 - this bombs elsewhere
        rescue => err
          if $log
            $log.debug err.to_s                 
            $log.debug err.backtrace.join("\n")
          end
          FFI::NCurses.endwin
          puts err
          puts err.backtrace.join("\n")
        ensure
        end

      end # while loop
    end # close
  rescue => err
    if $log
      $log.debug err.to_s
      $log.debug err.backtrace.join("\n")
    end
    FFI::NCurses.endwin
    puts err
    puts err.backtrace.join("\n")
  ensure
    #@window.destroy #unless @config[:window]
    destroy_window @pointer, @panel
    #FFI::NCurses.delwin(@pad)       if @pad
    destroy_pad
    return buttonindex 
  end
end
if __FILE__ == $PROGRAM_NAME
  def startup
    require 'logger'
    require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Time.now.to_s
    $log.info "Pad demo #{$0} started on #{today}"
  end
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
  end

  class Integer
    def ifzero v
      return self if self != 0
      return v
    end
  end

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

  startup
  begin
    h = 20
    w = 50
    p = Pad.new :filename => "pad.rb", :height => FFI::NCurses.LINES-1, :width => w, :row => 0, :col => 0, title: "pad.rb"
    p.run
  ensure
    FFI::NCurses.endwin
  end
end
