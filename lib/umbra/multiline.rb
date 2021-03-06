require 'umbra/widget'
# ----------------------------------------------------------------------------- #
#         File: multiline.rb
#  Description: A base class for lists and textboxes and tables, i.e. components
#               having multiple lines that are scrollable.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-05-08 - 11:54
#      License: MIT
#  Last update: 2018-06-10 10:50
# ----------------------------------------------------------------------------- #
#  multiline.rb Copyright (C) 2012-2018 j kepler
#
##  TODO allow setting of current_index programmatically
##  TODO is a row visible. visible? row. and make a row visible. programmatically
##  TODO insert delete a row (if editable)
#/


module Umbra

  ## Base class for widgets that have multiple lines and are scrollable.
  ## Preferably, use a concrete class such as Listbox, Table or Textbox.
  ## This is not editable by default. To delete or insert rows, set editable to true.
  class Multiline < Widget 

    attr_reader   :list                        # array containing data (usually Strings)
    attr_reader   :panned_cols                 ## How may columns has widget panned to right
    ## adjustment for searching for a pattern in a line, if adding text to start of string.
    ## Example, listbox adds one char to start. One may override and add two.
    attr_accessor  :search_offset              

    # index of focussed row, starting 0, index into the list supplied
    attr_reader   :current_index

    def initialize config={}, &block    # {{{
      @focusable          = false
      @editable           = false
      @pstart             = 0                  # which row does printing start from
      @current_index      = 0                  # index of row on which cursor is
      @search_offset      = 0                  # search has no offset

      ## PRESS event relates to pressing RETURN/ENTER (10)
      register_events([:LEAVE_ROW, :ENTER_ROW, :PRESS])

      super

      map_keys
      @row_offset         = 0
      @panned_cols               = 0     ## how many columns the view has panned.
                                  ## The name means panned_cols
      @curpos             = 0     ## Widget defines an accessor on this.
      @repaint_required   = true
    end

    ## Set list of data to be displayed.
    ## NOTE this can be called again and again, so we need to take care of change in size of data
    ## as well as things like current_index and selected_index or indices.
    def list=(alist)
      if !alist or alist.size == 0
        self.focusable=(false)
      else
        self.focusable=(true)
      end
      @list               = alist
      @repaint_required   = true
      @pstart = @current_index = 0
      @panned_cols               = 0
      $log.debug "  before multiline list= CHANGED "
      fire_handler(:CHANGED, self)    ## added 2018-05-08 - 
    end

    def row_count
      @list.size
    end


    # Calculate dimensions as late as possible, since we can have some other container such as a box,
    # determine the dimensions after creation.
    ## This is called by repaint.
    private def _calc_dimensions
      raise "Dimensions not supplied to multiline" if @row.nil? or @col.nil? or @width.nil? or @height.nil?
      @_calc_dimensions = true
      #@int_width  = self.width                     # internal width NOT USED ELSEWHERE
      height = self.height                    
      @scroll_lines ||= height/2
      @page_lines = height
    end

    def getvalue
      @list
    end

    # }}}

    ## repaints the entire multiline, called by +form+ {{{
    def repaint 
      _calc_dimensions unless @_calc_dimensions

      return unless @repaint_required
      return unless @list
      win                 = @graphic
      raise "window nil in multiline" unless win
      r,c                 = self.row, self.col 
      _attr               = @attr || NORMAL
      _color              = @color_pair || CP_WHITE
      curpos              = 1
      coffset             = 0

      rows               = getvalue 

      ht                  = self.height
      cur                 = @current_index
      st                  = pstart = @pstart           # previous start
      pend = pstart + ht -1                            # previous end
      if cur > pend
        st = (cur -ht) + 1 
      elsif cur < pstart
        st = cur
      end
      $log.debug "REPAINT #{self.class} : cur = #{cur} st = #{st} pstart = #{pstart} pend = #{pend} listsize = #{@list.size} "
      $log.debug "REPAINT ML : row = #{r} col = #{c} width = #{width}/#{@width},  height = #{ht}/#{@height} ( #{FFI::NCurses.COLS}   #{FFI::NCurses.LINES} "
      y = 0
      ctr = 0
      filler = " "*(self.width)
      rows.each_with_index {|_f, y| 
        next if y < st

        curpos = ctr if y == cur                                         ## used for setting row_offset

        #_state = state_of_row(y)     ## XXX should be move this into paint_row

        win.printstring(ctr + r, coffset+c, filler, _color )            ## print filler

        #paint_row( win, ctr+r, coffset+c, _f, y, _state)
        paint_row( win, ctr+r, coffset+c, _f, y)


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
    ##  to override just +print_row+ or +value_of_row+ or +_format_color+.
    ##
    ## @param [Window]   window pointer for printing
    ## @param [Integer]  row number to print on
    ## @param [Integer]  col:  column to print on
    ## @param [String]   line to be printed, usually String. Whatever was passed in to +list+ method.
    ## @param [Integer]  ctr: offset of row starting zero
    ## @param [String]   state: state of row (SELECTED CURRENT HIGHLIGHTED NORMAL)
    def paint_row(win, row, col, line, ctr)

      state = state_of_row(ctr)     

      ff = value_of_row(line, ctr, state)

      ff = _truncate_to_width( ff )   ## truncate and handle panning

      print_row(win, row, col, ff, ctr, state)
    end


    # do the actual printing of the row, depending on index and state
    # This method starts with underscore since it is only required to be overriden
    # if an object has special printing needs.
    def print_row(win, row, col, str, index, state)
      arr = color_of_row index, state
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
    def color_of_row index, state
      arr = case state
              #when :SELECTED
              #[@selected_color_pair, @selected_attr]
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
    alias :_format_color :color_of_row 




    # how to convert the line of the array to a simple String.
    # This is only required to be overridden if the list passed in is not an array of Strings.
    # @param the current row which could be a string or array or whatever was passed in in +list=()+.
    # @return [String] string to print. A String must be returned.
    def value_of_row line, ctr, state
      line
    end
    alias :_format_value :value_of_row 

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
      return _st
    end
    # }}}


    ## truncate string to width, and handle panning {{{
    def _truncate_to_width ff
      _width = self.width
      if ff
        if ff.size > _width
          # panned_cols can be greater than width then we get null
          if @panned_cols < ff.size
            ff = ff[@panned_cols..@panned_cols+_width-1] 
          else
            ff = ""
          end
        else
          if @panned_cols < ff.size
            ff = ff[@panned_cols..-1]
          else
            ff = ""
          end
        end
      end 
      ff = "" unless ff
      return ff
    end # }}}


    ## mapping of keys for multiline {{{
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
      ## C-h was not working, so trying C-j
      bind_key(FFI::NCurses::KEY_CTRL_J, 'scroll_left')  { scroll_left }
      bind_key(FFI::NCurses::KEY_CTRL_L, 'scroll_right')  { scroll_right }
      bind_key(?/, 'ask search')                         { ask_search }
      bind_key(?n, 'next match ')                        { find_more }
      @keys_mapped = true
    end

    ## on enter of this multiline
    def on_enter
      super
      on_enter_row @current_index
      # basically I need to only highlight the current index, not repaint all OPTIMIZE 
      #touch ; repaint ## 2018 why was i calling repaint here ??? causing error in messagebox since window nil
      touch 
    end

    # on leave of this multiline
    def on_leave
      super
      on_leave_row @current_index
      # basically I need to only unhighlight the current index, not repaint all OPTIMIZE 
      #touch ; repaint
      touch ##; repaint  ## why repaint here ?? when was this necessary ?
    end

    ## called when user leaves a row and when object is exited.
    def on_leave_row index
      fire_handler(:LEAVE_ROW, [index])     # 2018-03-26 - improve this
    end
    # called whenever a row entered.
    # Call when object entered, also. 
    def on_enter_row index
      fire_handler(:ENTER_ROW, [@current_index])     # 2018-03-26 - improve this
      # if cursor ahead of blen then fix it
      blen = current_row().size-1
      ## why -1 on above line. Empty lines will give -1
      blen = 0 if blen < 0
      if @curpos > blen
        @col_offset = blen - @panned_cols 
        @curpos = blen
        if @panned_cols > blen
          @panned_cols = blen - self.width  ## @int_width 2018-05-22 - 
          @panned_cols = 0 if @panned_cols < 0
          @col_offset = blen - @panned_cols 
        end
      end
      @col_offset = 0 if @col_offset < 0
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
      @curpos  = 0 
      @panned_cols    = 0
      set_col_offset 0
    end
    # goto end of line. 
    # This should be consistent with moving the cursor to the end of the row with right arrow
    def cursor_end
      blen = current_row().length
      if blen < self.width
        set_col_offset blen # just after the last character
        @panned_cols = 0
      else
        @panned_cols = blen-self.width #+2  # 2 is due to mark and space XXX could be a problem with textbox
        set_col_offset blen # just after the last character
      end
      @curpos = blen # this is position in array where editing or motion is to happen regardless of what you see
      # regardless of panned_cols (panning)
    end
    # returns current row as String
    # 2018-04-11 - NOTE this may not be a String so we convert it to string before returning
    # @return [String] row the cursor/user is on
    def current_row
      s = @list[@current_index]
      value_of_row s, @current_index, :CURRENT
    end
    # move cursor forward one character, called with KEY_RIGHT action.
    def cursor_forward
      blen = current_row().size # -1
      if @curpos < blen
        if add_col_offset(1)==-1  # go forward if you can, else scroll
          #@panned_cols += 1 if @panned_cols < self.width 
          @panned_cols += 1 if @panned_cols < blen
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
        if @panned_cols > 0
          @panned_cols -= 1
          @curpos -= 1
        else
          # do nothing
        end
      end
    end
    # advance col_offset (where cursor will be displayed on screen)
    # @param [Integer] advance by n (can be negative or positive)
    # @return -1 if cannot advance
    private def add_col_offset num
      x = @col_offset + num
      return -1 if x < 0
      return -1 if x > self.width  ## @int_width  2018-05-22 - 
      # is it a problem that i am directly changing col_offset ??? XXX
      @col_offset += num 
    end
    # sets the visual cursor on the window at correct place
    # NOTE be careful of curpos - panned_cols being less than 0
    # @param [Integer] position in data on the line
    private def set_col_offset x=@curpos
      @curpos = x || 0 # NOTE we set the index of cursor here - WHY TWO THINGS ??? XXX
      #return -1 if x < 0
      #return -1 if x > @width
      _w = self.width
      if x >= _w
        x = _w
        @col_offset = _w
        return
      end
      @col_offset = x 
      @col_offset = _w if @col_offset > _w
      return
    end
    def scroll_right ## cursor_forward
      blen = current_row().size-1
      @panned_cols += 1 if @panned_cols < blen
    end
    def scroll_left  ##cursor_backward
      @panned_cols -= 1 if @panned_cols > 0
    end
    # go to start of file (first line)
    def goto_start
      @current_index = 0
      @panned_cols = @curpos = 0
      set_col_offset 0
    end
    # go to end of file (last line)
    def goto_end
      @current_index = @list.size-1
      @panned_cols = @curpos = 0
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


    ## Multiline key handling. {{{
    ## Called by +form+ from form's +handle_key+ when this object is in focus.
    ## @param [Integer] ch: key caught by getch of window
    def handle_key ch
      old_current_index = @current_index
      old_panned_cols = @panned_cols
      old_col_offset = @col_offset

      ret = super
      return ret
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
      @repaint_required = true if old_panned_cols != @panned_cols or old_col_offset != @col_offset
    end

    ## convenience method for calling most used event of a widget
    ## Called by user programs.
    def command *args, &block
      bind_event :ENTER_ROW, *args, &block
    end # }}}

    #
    # event when user hits ENTER on a row, user would bind :PRESS
    # callers may use w.current_index or w.current_row or w.curpos.
    #
    #     obj.bind :PRESS { |w| w.current_row }
    #
    def fire_action_event
      return if @list.nil? || @list.size == 0
      #require 'canis/core/include/ractionevent'
      #aev = text_action_event
      #fire_handler :PRESS, aev
      fire_handler :PRESS, self
    end


##### TO TEST THE REST ############ 

    ## Is the given row visible
    ## UNTESTED
    def is_visible? _row
      j = _row - @pstart
      j >= 0 && j <= (self.height - 1)
    end

    # Ensure current row is visible, if not make it first row
    # NOTE - need to check if its at end and then reduce scroll at rows, check_prow does that
    # 
    # @param current_index (default if not given)
    #
    ## UNTESTED
    def ensure_visible _row = @current_index
      unless is_visible? _row
        @pstart = _row
      end
    end

    ## NOTE what about firing handlers when moving rows, i suppose that these will be called from a binding.
    ## UNTESTED
    def goto_line line
      return if line < 0 or line >= self.row_count
      @current_index = line
      ensure_visible line
    end
    #def each_line
      #@list.each_with_index do |line, ix|
        #line = self.value_of_row( line, ix, :NONE)
        #yield line
      #end
    #end

    ## Ask user for a pattern to look for in lines.
    ## Put cursor on first match.
    def ask_search
      str = get_string("Search:")
      return unless str
      ix = next_match str
      if ix
        @current_index, @curpos = ix
        set_col_offset @curpos   ## why do we need to do this also
        $log.debug "  ask_search ci: #{@current_index}  , #{@curpos} "
        @last_regex = str
      else
        alert "Pattern not found: #{str}"
      end
    end

    ## find more occurrences of match. This is bound to 'n' key.
    def find_more
      return unless @last_regex
      str = @last_regex
      $log.debug "  FIND MORE last_regex is : #{@last_regex} "
      ix = next_match @last_regex
      #return unless ix
      if ix
        @current_index, @curpos = ix
        set_col_offset @curpos   ## why do we need to do this also
      else
        alert "No more matches for: #{str}"
      end
    end

    ## find the first or next occurrence of a pattern
    ## @param str [String] pattern to match
    ## @param startline [Integer] line to start search on
    ## @param curpos [Integer] cursor position to start search on
    ## @param endline [Integer] line to end search on
    def next_match str, startline = nil,  _curpos = nil, endline = nil
      return unless str

      ## check current line for more occurrences.
      if !startline
        startline = @current_index
        _curpos ||= (@curpos + 1) # FIXME +1 should only happen if a search has already happened
        #_pos = @list[startline].index(str, _curpos)
        _pos = to_searchable(startline).index(str, _curpos)
        return [startline, _pos + search_offset] if _pos
        startline += 1
      end
      ## Check rest of file
      ## loop through array, check after startline to eof
      @list.each_with_index do | line, ix|
        next if ix < startline
        break if endline && ix > endline
        #_found = line.index(str)
        _found = to_searchable(ix).index(str)
        #$log.debug "  next_match: #{line}: #{_found}  " if _found
        return [ix, _found + search_offset] if _found
      end
      if startline > 0
        # this can get called again since startline was made 1 in above block. FIXME
        #return next_match str, 0, @current_index
      end
      return nil
    end


    ## This needs to be overridden in case of lists that contain something other than 
    ## `String` as their elements. In such a case, `search_offset` may need to be adjusted also.
    ## @param index [Integer] offset of row in list
    ## @return [String] searchable representation of list element at `index`
    def to_searchable index
      s = @list[index]
      case s
      when String
        return s                                       ## return the string as is.
      when Array
                                                       ## may need to be overridden by caller
        return s.join(" ")
      else
        raise "Don't know how to handle this datatype, please override to_searchable"
      end
    end


    ## UNTESTED
    def delete_at index
      return unless @list
      return unless @editable
      #@repaint_all = true
      @repaint_required = true
      @list.delete_at index
    end

    ## UNTESTED
    def insert index, line
      return unless @list
      return unless @editable
      #@repaint_all = true
      @repaint_required = true
      @list.insert index, line
    end

    ## delegate << []= etc but we need to fire CHANGED 

  end  # class
end    # module

#  vim:  comments=sr\:##,mb\:##,el\:#/,\:## :
