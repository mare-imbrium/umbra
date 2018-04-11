# ----------------------------------------------------------------------------- #
#         File: textbox.rb
#  Description: a multiline text view
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-24 - 12:39
#      License: MIT
#  Last update: 2018-04-10 08:17
# ----------------------------------------------------------------------------- #
#  textbox.rb  Copyright (C) 2012-2018 j kepler
##  TODO -----------------------------------
#  improve the object sent when row change or cursor movement 
#
#
#  ----------------------------------------
## CHANGELOG
#
#  ----------------------------------------
require 'umbra/widget'
module Umbra
class Textbox < Widget 
  attr_reader :list                   # list containing data 
  attr_accessor :file_name            # filename passed in for reading
  attr_accessor :selection_key        # key used to select a row
  attr_accessor :selected_index       # row selected, may change to plural
  attr_accessor :selected_color_pair  # row selected color_pair
  attr_accessor :selected_attr        # row selected color_pair
  #attr_accessor :cursor              # position of cursor in line ??
=begin
  attr_accessor :selected_mark               # row selected character
  attr_accessor :unselected_mark             # row unselected character (usually blank)
  attr_accessor :current_mark                # row current character (default is >)
=end

  def initialize config={}, &block
    @focusable          = true
    @editable           = false
    @pstart             = 0                  # which row does printing start from
    @current_index      = 0                  # index of row on which cursor is
    @selected_index     = nil                # index of row selected
    @selection_key      = 0                  # presently no selection. Actually 0 is Ctrl-Space.
    @highlight_attr     = FFI::NCurses::A_BOLD
    @to_print_border    = false
    @row_offset         = 0
    @col_offset         = 0
    @pcol               = 0
    @curpos             = 0                  # current cursor position in buffer (NOT screen/window/field)
=begin

    @selected_color_pair = CP_RED 
    @selected_attr = REVERSE
    @selected_mark    = 'x' # row selected character
    @unselected_mark  = ' ' # row unselected character (usually blank)
    @current_mark     = '>' # row current character (default is >)
=end
    register_events([:ENTER_ROW, :LEAVE_ROW, :CURSOR_MOVE]) # 
    super

    map_keys
    # internal width and height
    @repaint_required = true
  end
  def _calculate_dimensions
    @int_width = @width
    @int_height = @height      # used here only
    @scroll_lines ||= @int_height/2  # fix these to be perhaps half and one of ht
    @page_lines = @int_height
    @calculate_dimensions = true
  end
  # set list of data to be displayed.
  # NOTE this can be called again and again, so we need to take care of change in size of data
  # as well as things like current_index and selected_index or indices.
  def list=(alist)
    @list = alist
    @repaint_required = true
    @pstart = @current_index = 0
    @selected_index = nil
  end
  def file_name=(fp)
    raise "File #{fp} not readable"  unless File.readable? fp 
    return Dir.new(fp).entries if File.directory? fp
    case File.extname(fp)
    when '.tgz','.gz'
      cmd = "tar -ztvf #{fp}"
      content = %x[#{cmd}]
    when '.zip'
      cmd = "unzip -l #{fp}"
      content = %x[#{cmd}]
    when '.jar', '.gem'
      cmd = "tar -tvf #{fp}"
      content = %x[#{cmd}]
    when '.png', '.out','.jpg', '.gif','.pdf'
      content = "File #{fp} not displayable"
    when '.sqlite'
      cmd = "sqlite3 #{fp} 'select name from sqlite_master;'"
      content = %x[#{cmd}]
    else
      #content = File.open(fp,"r").readlines # this keeps newlines which mess with output
      content = File.open(fp,"r").read.split("\n")
    end
    self.list = content
    raise "list not set" unless @list

  end

  def repaint 
    _calculate_dimensions unless @calculate_dimensions
    return unless @repaint_required
    win = @graphic
    r,c = @row, @col 
    _attr = @attr || NORMAL
    _color = @color_pair || CP_WHITE
    _bordercolor = @border_color_pair || CP_BLUE
    rowpos = 1
    coffset = 0
    #width = win.width-1
    width = @width
    files = @list
    
    #ht = win.height-2
    ht = @height
    cur = @current_index
    st = pstart = @pstart           # previous start
    pend = pstart + ht -1  #- previous end
    if cur > pend
      st = (cur -ht) + 1 #+ 
    elsif cur < pstart
      st = cur
    end
    $log.debug "LISTBOX: cur = #{cur} st = #{st} pstart = #{pstart} pend = #{pend} listsize = #{@list.size} "
    hl = cur
    y = 0
    ctr = 0
    filler = " "*(width)
    files.each_with_index {|f, y| 
      next if y < st
      colr = CP_WHITE # white on bg -1
      mark = @unselected_mark
      if y == hl
        attr = @highlight_attr #FFI::NCurses::A_REVERSE
        mark = @current_mark
        rowpos = ctr
      else
        attr = FFI::NCurses::A_NORMAL
      end
      if y == @selected_index
        colr = @selected_color_pair
        attr = @selected_attr
        mark = @selected_mark
      end
      #ff = "#{mark} #{f}"
      ff = f
      if ff
        if ff.size > width
          #ff = ff[0...width]
          # pcol can be greater than width then we get null
          if @pcol < ff.size
            ff = ff[@pcol..@pcol+width-1] 
          else
            ff = ""
          end
        else
          if @pcol < ff.size
            ff = ff[@pcol..-1]
          else
            ff = ""
          end
        end
      end
      ff = "" unless ff

      win.printstring(ctr + r, coffset+c, filler, colr )
      win.printstring(ctr + r, coffset+c, ff, colr, attr)
      ctr += 1 
      @pstart = st
      break if ctr >= ht #-
    }
    @row_offset = rowpos 
    #@col_offset = coffset # this way form can pick it up XXX can't override it like this
    @repaint_required = false
  end

  def getvalue
    @list
  end

  # ensure text has been passed or action
  def getvalue_for_paint
    raise
    ret = getvalue
    #@text_offset = @surround_chars[0].length
    #@surround_chars[0] + ret + @surround_chars[1]
  end


  def map_keys
    return if @keys_mapped
    bind_keys([?k,FFI::NCurses::KEY_UP], "Up")         { cursor_up }
    bind_keys([?j,FFI::NCurses::KEY_DOWN], "Down")     { cursor_down }
    bind_keys([?l,FFI::NCurses::KEY_RIGHT], "Right")   { cursor_forward }
    bind_keys([?h,FFI::NCurses::KEY_LEFT], "Left")     { cursor_backward }
    bind_key(?g, 'goto_start')                         { goto_start }
    bind_key(?G, 'goto_end')                           { goto_end }
    bind_key(FFI::NCurses::KEY_CTRL_A, 'cursor_home')  { cursor_home }
    bind_key(FFI::NCurses::KEY_CTRL_E, 'cursor_end')   { cursor_end }
    bind_key(FFI::NCurses::KEY_CTRL_F, 'page_forward') { page_forward }
    bind_key(32, 'page_forward')                       { page_forward }
    bind_key(FFI::NCurses::KEY_CTRL_B, 'page_backward'){ page_backward }
    bind_key(FFI::NCurses::KEY_CTRL_U, 'scroll_up')    { scroll_up }
    bind_key(FFI::NCurses::KEY_CTRL_D, 'scroll_down')  { scroll_down }
    @keys_mapped = true
  end

  # listbox key handling
  def handle_key ch
    #   save old positions so we know movement has happened
    old_current_index = @current_index
    old_pcol = @pcol
    old_col_offset = @col_offset

    case ch
    when @selection_key
      @repaint_required = true  
      if @selected_index == @current_index 
        @selected_index = nil
      else
        @selected_index = @current_index 
      end
    else
      ret = super
      return ret
    end
  ensure
    @current_index = 0 if @current_index < 0
    @current_index = @list.size-1 if @current_index >= @list.size
    @repaint_required = true  if @current_index != old_current_index
    if @current_index != old_current_index or @pcol != old_pcol or @col_offset != old_col_offset
      if @current_index != old_current_index 
        on_leave_row old_current_index
        on_enter_row @current_index
        #fire_handler(:CHANGE_ROW, [old_current_index, @current_index, ch ])     # 2018-03-26 - improve this
      end
      @repaint_required = true 
      fire_handler(:CURSOR_MOVE, [@col_offset, @current_index, @curpos, @pcol, ch ])     # 2018-03-25 - improve this
    end
  end
  # advance col_offset (where cursor will be displayed on screen)
  # @param [Integer] advance by n (can be negative or positive)
  # @return -1 if cannot advance
  private def add_col_offset num
    x = @col_offset + num
    return -1 if x < 0
    return -1 if x > @int_width 
    # is it a problem that i am directly changing col_offset ??? XXX
    @col_offset += num 
  end
  # returns current row
  def current_row
    @list[@current_index]
  end

  # move cursor forward one character, called with KEY_RIGHT action.
  def cursor_forward
    blen = current_row().size-1
    if @curpos < blen
      if add_col_offset(1)==-1  # go forward if you can, else scroll
        #@pcol += 1 if @pcol < @width 
        @pcol += 1 if @pcol < blen
      end
      @curpos += 1
    end
  end
  def cursor_backward

    if @col_offset > 0
      @curpos -= 1
      add_col_offset -1
    else
      # cur is on the first col, then scroll left
      if @pcol > 0
        @pcol -= 1
        @curpos -= 1
      else
        # do nothing
      end
    end
  end
    # position cursor at start of field
    def cursor_home
      @curpos = 0
      @pcol = 0
      set_col_offset 0
    end
    # goto end of line. 
    # This should be consistent with moving the cursor to the end of the row with right arrow
    def cursor_end
      blen = current_row().length
      if blen < @int_width
        set_col_offset blen # just after the last character
        @pcol = 0
      else
        @pcol = blen-@int_width
        set_col_offset blen
      end
      @curpos = blen # this is position in array where editing or motion is to happen regardless of what you see
      # regardless of pcol (panning)
    end
    # go to start of file (first line)
    def goto_start
      @current_index = 0
      @pcol = @curpos = 0
      set_col_offset 0
    end
    # go to end of file (last line)
    def goto_end
      @current_index = @list.size-1
    end
    def scroll_down
      @current_index += @scroll_lines
    end
    def scroll_up
      @current_index -= @scroll_lines
    end
    def page_backward
      @current_index -= @page_lines
    end
    def page_forward
      @current_index += @page_lines
    end
  # sets the visual cursor on the window at correct place
  # NOTE be careful of curpos - pcol being less than 0
  # @param [Integer] position in data on the line
  private def set_col_offset x=@curpos
    @curpos = x || 0 # NOTE we set the index of cursor here - WHY TWO THINGS ??? XXX
    #return -1 if x < 0
    #return -1 if x > @width
    if x >= @int_width
      x = @int_width
      @col_offset = @int_width 
      return
    end
    @col_offset = x 
    @col_offset = @int_width if @col_offset > @int_width
    return
  end
  def cursor_up
    @current_index -= 1
  end
  # go to next row
  def cursor_down
    @current_index += 1
  end
  def on_enter
    super
    on_enter_row @current_index
  end
  def on_leave
    super
    on_leave_row @current_index
  end
  # called when object leaves a row and when object is exited.
  def on_leave_row index
    fire_handler(:LEAVE_ROW, [index])     # 2018-03-26 - improve this
  end
  # called whenever a row entered.
  # Call when object entered, also. 
  def on_enter_row index
    #fire_handler(:ENTER_ROW, [old_current_index, @current_index, ch ])     # 2018-03-26 - improve this
    fire_handler(:ENTER_ROW, [@current_index])     # 2018-03-26 - improve this
    # if cursor ahead of blen then fix it
    blen = current_row().size-1
    if @curpos > blen
      @col_offset = blen - @pcol 
      @curpos = blen
      if @pcol > blen
        @pcol = blen - @int_width
        @pcol = 0 if @pcol < 0
        @col_offset = blen - @pcol 
      end
    end
    @col_offset = 0 if @col_offset < 0
  end
  ## border {{{
  private def print_border row, col, height, width, color, att=FFI::NCurses::A_NORMAL
    raise
    pointer = @graphic.pointer
    FFI::NCurses.wattron(pointer, FFI::NCurses.COLOR_PAIR(color) | att)
    FFI::NCurses.mvwaddch pointer, row, col, FFI::NCurses::ACS_ULCORNER
    FFI::NCurses.mvwhline( pointer, row, col+1, FFI::NCurses::ACS_HLINE, width-2)
    FFI::NCurses.mvwaddch pointer, row, col+width-1, FFI::NCurses::ACS_URCORNER
    FFI::NCurses.mvwvline( pointer, row+1, col, FFI::NCurses::ACS_VLINE, height-2)

    FFI::NCurses.mvwaddch pointer, row+height-1, col, FFI::NCurses::ACS_LLCORNER
    FFI::NCurses.mvwhline(pointer, row+height-1, col+1, FFI::NCurses::ACS_HLINE, width-2)
    FFI::NCurses.mvwaddch pointer, row+height-1, col+width-1, FFI::NCurses::ACS_LRCORNER
    FFI::NCurses.mvwvline( pointer, row+1, col+width-1, FFI::NCurses::ACS_VLINE, height-2)
    FFI::NCurses.wattroff(pointer, FFI::NCurses.COLOR_PAIR(color) | att)
  end # }}}
end 
end # module
