# ----------------------------------------------------------------------------- #
#         File: textbox.rb
#  Description: a multiline text view
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-24 - 12:39
#      License: MIT
#  Last update: 2018-05-10 11:06
# ----------------------------------------------------------------------------- #
#  textbox.rb  Copyright (C) 2012-2018 j kepler
##  TODO -----------------------------------
#  improve the object sent when row change or cursor movement 
## 2018-05-08 - extend Multiline
#
#  ----------------------------------------
## CHANGELOG
#
#  ----------------------------------------
require 'umbra/multiline'
module Umbra
class Textbox < Multiline 
  attr_accessor :file_name            # filename passed in for reading
  #attr_accessor :cursor              # position of cursor in line ??
=begin
  attr_accessor :selected_mark               # row selected character
  attr_accessor :unselected_mark             # row unselected character (usually blank)
  attr_accessor :current_mark                # row current character (default is >)
=end

  def initialize config={}, &block
    @highlight_attr     = FFI::NCurses::A_BOLD
    @row_offset         = 0
    @col_offset         = 0
    @curpos             = 0                  # current cursor position in buffer (NOT screen/window/field)
    #register_events([:ENTER_ROW, :LEAVE_ROW, :CURSOR_MOVE]) # 
    register_events([:CURSOR_MOVE]) # 
    super

  end
  # set list of data to be displayed from filename.  {{{
  # NOTE this can be called again and again, so we need to take care of change in size of data
  # as well as things like current_index and selected_index or indices.
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

  end # }}}

  # returns current row
  def current_row
    @list[@current_index]
  end


  ## textbox key handling  
  ## Textbox varies from multiline in that it fires a cursor_move event whrease the parent 
  ##  fires a cursor_move event which is mostly used for testing out
  def handle_key ch
    begin 
      ret = super
      return ret
    ensure
      if @repaint_required
        fire_handler(:CURSOR_MOVE, [@col_offset, @current_index, @curpos, @pcol, ch ])     # 2018-03-25 - improve this
      end
    end
  end
  def OLDhandle_key ch # {{{
    return :UNHANDLED unless @list
    #   save old positions so we know movement has happened
    old_current_index = @current_index
    old_pcol = @pcol
    old_col_offset = @col_offset

    begin
        ret = super
        return ret
    ensure
      @current_index = 0 if @current_index < 0
      @current_index = @list.size-1 if @current_index >= @list.size
      @repaint_required = true  if @current_index != old_current_index
      if @current_index != old_current_index or @pcol != old_pcol or @col_offset != old_col_offset
        if @current_index != old_current_index 
          on_leave_row old_current_index
          on_enter_row @current_index
        end
        @repaint_required = true 
        fire_handler(:CURSOR_MOVE, [@col_offset, @current_index, @curpos, @pcol, ch ])     # 2018-03-25 - improve this
      end
    end
  end # }}}
  # advance col_offset (where cursor will be displayed on screen) {{{
  # @param [Integer] advance by n (can be negative or positive)
  # @return -1 if cannot advance
  private def OLDadd_col_offset num
    x = @col_offset + num
    return -1 if x < 0
    return -1 if x > @int_width 
    # is it a problem that i am directly changing col_offset ??? XXX
    @col_offset += num 
  end

  # move cursor forward one character, called with KEY_RIGHT action.
  def OLDcursor_forward
    blen = current_row().size-1
    if @curpos < blen
      if add_col_offset(1)==-1  # go forward if you can, else scroll
        #@pcol += 1 if @pcol < @width 
        @pcol += 1 if @pcol < blen
      end
      @curpos += 1
    end
  end
  def OLDcursor_backward

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
  def OLDcursor_home
    @curpos = 0
    @pcol = 0
    set_col_offset 0
  end
  # goto end of line. 
  # This should be consistent with moving the cursor to the end of the row with right arrow
  def OLDcursor_end
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
  def OLDgoto_start
    @current_index = 0
    @pcol = @curpos = 0
    set_col_offset 0
  end
  # go to end of file (last line)
  def OLDgoto_end
    @current_index = @list.size-1
  end
  # sets the visual cursor on the window at correct place
  # NOTE be careful of curpos - pcol being less than 0
  # @param [Integer] position in data on the line
  private def OLD_set_col_offset x=@curpos
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
  # called whenever a row entered.
  # Call when object entered, also. 
  def OLD_on_enter_row index
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
  end # }}}
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
