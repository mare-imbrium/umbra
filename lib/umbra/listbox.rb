require 'umbra/widget'
# ----------------------------------------------------------------------------- #
#         File: listbox.rb
#  Description: list widget that displays a list of items
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-19 
#      License: MIT
#  Last update: 2018-04-11 10:17
# ----------------------------------------------------------------------------- #
#  listbox.rb  Copyright (C) 2012-2018 j kepler
#  == TODO 
#  currently only do single selection, we may do multiple at a later date.
#  insert/delete a row ??
#  ----------------
module Umbra
class Listbox < Widget 
  attr_reader   :list                        # list containing data 
  attr_accessor :selection_key               # key used to select a row
  attr_accessor :selected_index              # row selected, may change to plural
  attr_accessor :selected_color_pair         # row selected color_pair
  attr_accessor :selected_attr               # row selected color_pair
  attr_accessor :selected_mark               # row selected character
  attr_accessor :unselected_mark             # row unselected character (usually blank)
  attr_accessor :current_mark                # row current character (default is >)

  # index of focussed row, starting 0, index into the data supplied
  attr_reader :current_index
  def initialize config={}, &block
    @focusable          = true
    @editable           = false
    @pstart             = 0                  # which row does printing start from
    @current_index      = 0                  # index of row on which cursor is
    @selected_index     = nil                # index of row selected
    @selection_key      = ?s.getbyte(0)      # 's' used to select/deselect
    @selected_color_pair = CP_RED 
    @selected_attr      = REVERSE
    @row_offset         = 0
    @selected_mark      = 'x'                # row selected character
    @unselected_mark    = ' '                # row unselected character (usually blank)
    @current_mark       = '>'                # row current character (default is >)
    register_events([:LEAVE_ROW, :ENTER_ROW, :LIST_SELECTION_EVENT])
    super

    map_keys
    @pcol               = 0
    @repaint_required   = true
  end
  # set list of data to be displayed.
  # NOTE this can be called again and again, so we need to take care of change in size of data
  # as well as things like current_index and selected_index or indices.
  # clear the listbox is list is smaller or empty FIXME
  def list=(alist)
    @list               = alist
    @repaint_required   = true
    @pstart = @current_index = 0
    @selected_index     = nil
    @pcol               = 0
  end
  # Calculate dimensions as late as possible, since we can have some other container such as a box,
  # determine the dimensions after creation.
  private def _calc_dimensions
    raise "Dimensions not supplied to listbox" if @row.nil? or @col.nil? or @width.nil? or @height.nil?
    @_calc_dimensions = true
    @int_width  = @width                     # internal width NOT USED ELSEWHERE
    @int_height = @height                    # internal height  USED HERE ONLy REDUNDANT FIXME
    @scroll_lines ||= @int_height/2
    @page_lines = @int_height
  end

  def repaint 
    _calc_dimensions unless @_calc_dimensions

    return unless @repaint_required
    win                 = @graphic
    r,c                 = @row, @col 
    _attr               = @attr || NORMAL
    _color              = @color_pair || CP_WHITE
    curpos              = 1
    coffset             = 0
    width               = @width
    #files               = @list
    files               = getvalue # allows overriding
    
    ht                  = @height
    cur                 = @current_index
    st                  = pstart = @pstart           # previous start
    pend = pstart + ht -1                            # previous end
    if cur > pend
      st = (cur -ht) + 1 
    elsif cur < pstart
      st = cur
    end
    $log.debug "LISTBOX: cur = #{cur} st = #{st} pstart = #{pstart} pend = #{pend} listsize = #{@list.size} "
    hl = cur
    y = 0
    ctr = 0
    filler = " "*(width)
    files.each_with_index {|_f, y| 
      next if y < st
      f = getvalue_for_paint(_f)
      #colr              = CP_WHITE # white on bg -1
      colr              = _color           # 2018-04-06 - set but not used
      mark              = @unselected_mark
      if y == hl 
        # highlight only if object is focussed, otherwise just show mark
        if @state == :HIGHLIGHTED
          attr            = FFI::NCurses::A_REVERSE
        end
        mark            = @current_mark
        curpos          = ctr
      else
        attr            = _attr
      end
      if y == @selected_index
        colr            = @selected_color_pair
        attr            = @selected_attr
        mark            = @selected_mark
      end
      ff = "#{mark} #{f}"
      #if ff.size > width
        #ff = ff[0...width]
      #end
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
      break if ctr >= ht 
    }
    ## if counter < ht then we need to clear the rest in case there was data earlier
    if ctr < ht
      while ctr < ht
        win.printstring(ctr + r, coffset+c, filler, _color )
        ctr += 1
      end
    end
    @row_offset = curpos #+ border_offset
    @col_offset = coffset
    @repaint_required = false
  end

  def getvalue
    @list
  end

  # 
  # how to paint the specific row
  # @param the current row which could be a string or array or whatever was passed in in +list=()+.
  # @return [String] string to print. A String must be returned.
  def _format line
    line
  end
  alias :_format :getvalue_for_paint


  def map_keys
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
    return if @keys_mapped
  end

  def on_enter
    super
    on_enter_row @current_index
    # basically I need to only highlight the current index, not repaint all OPTIMIZE 
    touch ; repaint
  end
  def on_leave
    super
    on_leave_row @current_index
    # basically I need to only unhighlight the current index, not repaint all OPTIMIZE 
    touch ; repaint
  end
  # called when object leaves a row and when object is exited.
  def on_leave_row index
    fire_handler(:LEAVE_ROW, [index])     # 2018-03-26 - improve this
  end
  # called whenever a row entered.
  # Call when object entered, also. 
  def on_enter_row index
    fire_handler(:ENTER_ROW, [@current_index])     # 2018-03-26 - improve this
  end
  def cursor_up
    @current_index -= 1
  end
  # go to next row
  def cursor_down
    @current_index += 1
  end
    # position cursor at start of field
    def cursor_home
      @curpos  = 0  # UNUSED RIGHT NOW
      @pcol    = 0
    end
    # goto end of line. 
    # This should be consistent with moving the cursor to the end of the row with right arrow
    def cursor_end
      blen = current_row().length
      if blen < @width
        @pcol = 0
      else
        @pcol = blen-@width+2  # 2 is due to mark and space
      end
      @curpos = blen # this is position in array where editing or motion is to happen regardless of what you see
      # regardless of pcol (panning)
    end
    # returns current row
    def current_row
      @list[@current_index]
    end
    def cursor_forward
      blen = current_row().size-1
      @pcol += 1 if @pcol < blen
    end
    def cursor_backward
      @pcol -= 1 if @pcol > 0
    end
    # go to start of file (first line)
    def goto_start
      @current_index = 0
      @pcol = @curpos = 0
    end
    # go to end of file (last line)
    def goto_end
      @current_index = @list.size-1
      @pcol = @curpos = 0
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
  # listbox key handling
  def handle_key ch
    old_current_index = @current_index
    old_pcol = @pcol
    case ch
    when @selection_key
      @repaint_required = true  
      if @selected_index == @current_index 
        @selected_index = nil
      else
        @selected_index = @current_index 
      end
      fire_handler :LIST_SELECTION_EVENT, self   # use selected_index to know which one
    else
      ret = super
      return ret
    end
  ensure
    @current_index = 0 if @current_index < 0
    @current_index = @list.size-1 if @current_index >= @list.size
    if @current_index != old_current_index
      on_leave_row old_current_index
      on_enter_row @current_index
      @repaint_required = true  
    end
    @repaint_required = true if old_pcol != @pcol
  end

  def command *args, &block
    bind_event :ENTER_ROW, *args, &block
  end
  def print_border row, col, height, width, color, att=FFI::NCurses::A_NORMAL
    raise "deprecated"
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
  end
end 
end # module
