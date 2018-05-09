require 'umbra/widget'
# ----------------------------------------------------------------------------- #
#         File: multiline.rb
#  Description: 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-05-08 - 11:54
#      License: MIT
#  Last update: 2018-05-09 10:05
# ----------------------------------------------------------------------------- #
#  multiline.rb Copyright (C) 2012-2018 j kepler
module Umbra
class Multiline < Widget 
  attr_reader   :list                        # array containing data (usually Strings)
  #
  # index of focussed row, starting 0, index into the list supplied
  attr_reader   :current_index

  attr_accessor :selection_allowed           # does this class allow row selection (should be class level)
  attr_accessor :selection_key               # key used to select a row
  attr_accessor :selected_index              # row selected, may change to plural
  attr_accessor :selected_color_pair         # row selected color_pair
  attr_accessor :selected_attr               # row selected color_pair
  attr_accessor :selected_mark               # row selected character
  attr_accessor :unselected_mark             # row unselected character (usually blank)
  attr_accessor :current_mark                # row current character (default is >)


  def initialize config={}, &block    # {{{
    @focusable          = false
    @editable           = false
    @pstart             = 0                  # which row does printing start from
    @current_index      = 0                  # index of row on which cursor is
    @selection_allowed  = false              # does this class allow selection of row
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
  def list=(alist)
    if !alist or alist.size == 0
      self.focusable=(false)
    else
      self.focusable=(true)
    end
    @list               = alist
    @repaint_required   = true
    @pstart = @current_index = 0
    @selected_index     = nil
    @pcol               = 0
    fire_handler(:CHANGED, self)    ## added 2018-05-08 - 
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

  def getvalue
    @list
  end

  # }}}
 
  ## repaints the entire listbox, called by +form+ {{{
  def repaint 
    _calc_dimensions unless @_calc_dimensions

    return unless @repaint_required
    return unless @list
    win                 = @graphic
    r,c                 = @row, @col 
    _attr               = @attr || NORMAL
    _color              = @color_pair || CP_WHITE
    curpos              = 1
    coffset             = 0
    
    rows               = getvalue 
    
    ht                  = @height
    cur                 = @current_index
    st                  = pstart = @pstart           # previous start
    pend = pstart + ht -1                            # previous end
    if cur > pend
      st = (cur -ht) + 1 
    elsif cur < pstart
      st = cur
    end
    $log.debug " #{self.class} : cur = #{cur} st = #{st} pstart = #{pstart} pend = #{pend} listsize = #{@list.size} "
    y = 0
    ctr = 0
    filler = " "*(@width)
    rows.each_with_index {|_f, y| 
      next if y < st

      curpos = ctr if y == cur                                         ## used for setting row_offset

      _state = state_of_row(y)     ## XXX should be move this into paint_row

      win.printstring(ctr + r, coffset+c, filler, _color )            ## print filler

      paint_row( win, ctr+r, coffset+c, _f, y, _state)


      ctr += 1 
      @pstart = st
      break if ctr >= ht 
    }
    ## if counter < ht then we need to clear the rest in case there was data earlier {{{
    if ctr < ht
      while ctr < ht
        win.printstring(ctr + r, coffset+c, filler, _color )
        ctr += 1
      end
    end # }}}
    @row_offset = curpos                             ## used by +widget+ in +rowcol+ called by +Form+
    #@col_offset = coffset    ## NOTE listbox had this line, but it interferes with textbox
    @repaint_required = false
  end  # }}}

  ## Paint given row.  {{{
  ## This is not be be called by user, but may be overridden if caller wishes
  ##  to completely change the presentation of each row. In most cases, it should suffice
  ##  to override just +_print_row+ or +_format_value+ or +_format_color+.
  ##
  ## @param [Window]   window pointer for printing
  ## @param [Integer]  row number to print on
  ## @param [Integer]  col:  column to print on
  ## @param [String]   line to be printed, usually String. Whatever was passed in to +list+ method.
  ## @param [Integer]  ctr: offset of row starting zero
  ## @param [String]   state: state of row (SELECTED CURRENT HIGHLIGHTED NORMAL)
  def paint_row(win, row, col, line, ctr, state)

      f = _format_value(line)

      mark = _format_mark(ctr, state)
      ff = "#{mark}#{f}"

      ff = _truncate_to_width( ff )   ## truncate and handle panning

      _print_row(win, row, col, ff, ctr, state)
  end


  # do the actual printing of the row, depending on index and state
  # This method starts with underscore since it is only required to be overriden
  # if an object has special printing needs.
  def _print_row(win, row, col, str, index, state)
    arr = _format_color index, state
    win.printstring(row, col, str, arr[0], arr[1])
  end

  # Each row can be in one of the following states:
  #  1. HIGHLIGHTED: cursor is on the row, and the list is focussed (user is in it)
  #  2. CURRENT    : cursor was on this row, now user has exited the list
  #  3. SELECTED   : user has selected this row (this can also have above two states actually)
  #  4. NORMAL     : All other rows: not selected, not under cursor
  # returns color, attrib for given row
  # @param index of row in the list
  # @param state of row in the list (see above states)
  def _format_color index, state
    arr = case state
    when :SELECTED
      [@selected_color_pair, @selected_attr]
    when :HIGHLIGHTED
      [@highlight_color_pair || CP_WHITE, @highlight_attr || REVERSE]
    when :CURRENT
      [@color_pair, @attr]
    when :NORMAL
      _color = CP_CYAN
      _color = CP_WHITE if index % 2 == 0
      #_color = @alt_color_pair if index % 2 == 0
      [@color_pair || _color, @attr || NORMAL]
    end
    return arr
  end
  alias :color_of_row :_format_color 


  def _format_mark index, state
      mark = case state
             when :SELECTED
               @selected_mark
             when :HIGHLIGHTED, :CURRENT
               @current_mark
             else
               @unselected_mark
             end
  end
  alias :mark_of_row :_format_mark 
   

  # how to convert the line of the array to a simple String.
  # This is only required to be overridden if the list passed in is not an array of Strings.
  # @param the current row which could be a string or array or whatever was passed in in +list=()+.
  # @return [String] string to print. A String must be returned.
  def _format_value line
    line
  end
  alias :value_of_row :_format_value 
  
  def state_of_row ix
      _st = :NORMAL
      cur = @current_index
      if ix == cur # current row, row on which cursor is or was
        ## highlight only if object is focussed, otherwise just show mark
        if @state == :HIGHLIGHTED
          _st = :HIGHLIGHTED
        else
          ## cursor was on this row, but now user has tabbed out
          _st = :CURRENT
        end
      end
      if ix == @selected_index
        _st = :SELECTED
      end # 
      return _st
  end
  # }}}


  ## truncate string to width, and handle panning {{{
  def _truncate_to_width ff
      if ff
        if ff.size > @width
          # pcol can be greater than width then we get null
          if @pcol < ff.size
            ff = ff[@pcol..@pcol+@width-1] 
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
      return ff
  end # }}}


  ## mapping of keys for listbox {{{
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

  ## on enter of this listbox
  def on_enter
    super
    on_enter_row @current_index
    # basically I need to only highlight the current index, not repaint all OPTIMIZE 
    touch ; repaint
  end

  # on leave of this listbox
  def on_leave
    super
    on_leave_row @current_index
    # basically I need to only unhighlight the current index, not repaint all OPTIMIZE 
    touch ; repaint
  end
  
  ## called when user leaves a row and when object is exited.
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
        @pcol = blen-@width+2  # 2 is due to mark and space XXX could be a problem with textbox
      end
      @curpos = blen # this is position in array where editing or motion is to happen regardless of what you see
      # regardless of pcol (panning)
    end
    # returns current row as String
    # 2018-04-11 - NOTE this may not be a String so we convert it to string before returning
    # @return [String] row the cursor/user is on
    def current_row
      s = @list[@current_index]
      _format_value s
    end
    def cursor_forward
      # FIXME Take from textbox
      blen = current_row().size-1
      @pcol += 1 if @pcol < blen
    end
    def cursor_backward
      # FIXME Take from textbox
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
    # }}}


    ## Listbox key handling. {{{
    ## Called by +form+ from form's +handle_key+ when this object is in focus.
    ## @param [Integer] ch: key caught by getch of window
    def handle_key ch
      old_current_index = @current_index
      old_pcol = @pcol
      if @selection_allowed and ch == @selection_key
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
      ## NOTE: it is possible that a block called above may have cleared the list.
      ##  In that case, the on_enter_row will crash. I had put a check here, but it 
      ##    has vanished ???
      @current_index = 0 if @current_index < 0
      @current_index = @list.size-1 if @current_index >= @list.size
      if @current_index != old_current_index
        on_leave_row old_current_index
        on_enter_row @current_index
        @repaint_required = true  
      end
      @repaint_required = true if old_pcol != @pcol
    end

    ## convenience method for calling most used event of a widget
    ## Called by user programs.
    def command *args, &block
      bind_event :ENTER_ROW, *args, &block
    end # }}}

end 
end # module