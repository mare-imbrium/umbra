require 'umbra/widget'
# ----------------------------------------------------------------------------- #
#         File: listbox.rb
#  Description: list widget that displays a list of items
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-19 
#      License: MIT
#  Last update: 2018-04-08 08:57
# ----------------------------------------------------------------------------- #
#  listbox.rb  Copyright (C) 2012-2018 j kepler
#  == TODO 
#  left and right scrolling
#  currently only do single selection, we may do multiple at a later date.
#  FIXME remove border stuff from here totally
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
    @selection_key      = 32                 # SPACE used to select/deselect
    @selected_color_pair = CP_RED 
    @selected_attr      = REVERSE
    @row_offset         = 0
    @selected_mark      = 'x'                # row selected character
    @unselected_mark    = ' '                # row unselected character (usually blank)
    @current_mark       = '>'                # row current character (default is >)
    register_events([:LEAVE_ROW, :ENTER_ROW, :LIST_SELECTION_EVENT])
    super

    map_keys
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
    #width              = win.width-1
    width               = @width
    files               = @list
    
    #ht = win.height-2
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
    files.each_with_index {|f, y| 
      next if y < st
      #colr              = CP_WHITE # white on bg -1
      colr              = _color           # 2018-04-06 - set but not used
      mark              = @unselected_mark
      if y == hl
        attr            = FFI::NCurses::A_REVERSE
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
      if ff.size > width
        ff = ff[0...width]
      end

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

  # ensure text has been passed or action
  def getvalue_for_paint
    raise
    ret = getvalue
  end


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
    bind_key(FFI::NCurses::KEY_CTRL_B, 'page_backward'){ page_backward }
    bind_key(FFI::NCurses::KEY_CTRL_U, 'scroll_up')    { scroll_up }
    bind_key(FFI::NCurses::KEY_CTRL_D, 'scroll_down')  { scroll_down }
    return if @keys_mapped
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
      @curpos = 0  # UNUSED RIGHT NOW
      @pcol = 0
    end
    # goto end of line. 
    # This should be consistent with moving the cursor to the end of the row with right arrow
    def cursor_end
      # TODO
    end
    def cursor_forward
      # TODO
    end
    def cursor_backward
    end
    # go to start of file (first line)
    def goto_start
      @current_index = 0
      @pcol = @curpos = 0
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
  # listbox key handling
  def handle_key ch
    old_current_index = @current_index
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
