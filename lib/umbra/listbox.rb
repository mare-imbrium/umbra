require 'umbra/widget'
# ----------------------------------------------------------------------------- #
#         File: listbox.rb
#  Description: list widget that displays a list of items
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-19 
#      License: MIT
#  Last update: 2018-03-31 14:37
# ----------------------------------------------------------------------------- #
#  listbox.rb  Copyright (C) 2012-2018 j kepler
#  == TODO 
#  keys
#  events
#  insert/delete a row
#  ----------------
class Listbox < Widget 
  attr_reader :list  # list containing data 
  attr_accessor :selection_key  # key used to select a row
  attr_accessor :selected_index  # row selected, may change to plural
  attr_accessor :selected_color_pair  # row selected color_pair
  attr_accessor :selected_attr  # row selected color_pair
  attr_accessor :selected_mark  # row selected character
  attr_accessor :unselected_mark  # row unselected character (usually blank)
  attr_accessor :current_mark  # row current character (default is >)

  def initialize config={}, &block
    @focusable = true
    @editable = false
    @pstart = 0    # which row does printing start from
    @current_index = 0 # index of row on which cursor is
    @selected_index = nil # index of row selected
    @selection_key = 32    # SPACE used to select/deselect
    @selected_color_pair = CP_RED 
    @selected_attr = REVERSE
    @to_print_border = true
    @row_offset = 0
    @selected_mark    = 'x' # row selected character
    @unselected_mark  = ' ' # row unselected character (usually blank)
    @current_mark     = '>' # row current character (default is >)
    register_events([:LEAVE_ROW, :ENTER_ROW, :LIST_SELECTION_EVENT]) # TODO events
    super

    map_keys
    @row_offset = 2 if @to_print_border
    @repaint_required = true
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
  # should a border be printed on the listbox
  def border flag=true
    @to_print_border = flag
    @row_offset = 2
    @row_offset = 0 unless flag
    @pstart = 0
    @repaint_required = true
  end

  def repaint 
    return unless @repaint_required
    win = @graphic
    r,c = @row, @col 
    _attr = @attr || NORMAL
    _color = @color_pair || CP_WHITE
    _bordercolor = @border_color_pair || CP_BLUE
    curpos = 1
    coffset = 0
    #width = win.width-1
    width = @width
    files = @list
    
    #ht = win.height-2
    ht = @height
    border_offset = 0
    if @to_print_border
      print_border r, c, ht, width, _bordercolor, _attr
      border_offset = 1
      coffset = 1 # same as border offset I think from left
      ht -= 2
      width -= 2
      r += 1
    end
    cur = @current_index
    st = pstart = @pstart           # previous start
    pend = pstart + ht -1  #-border_offset -border_offset           # previous end
    if cur > pend
      st = (cur -ht) + 1 #+ border_offset + border_offset
    elsif cur < pstart
      st = cur
    end
    $log.debug "LISTBOX: cur = #{cur} st = #{st} pstart = #{pstart} pend = #{pend} listsize = #{@list.size} "
    hl = cur
    y = 0
    ctr = 0
    # 2 is for col offset  and border
    filler = " "*(width)
    files.each_with_index {|f, y| 
      next if y < st
      colr = CP_WHITE # white on bg -1
      mark = @unselected_mark
      if y == hl
        attr = FFI::NCurses::A_REVERSE
        mark = @current_mark
        curpos = ctr
      else
        attr = FFI::NCurses::A_NORMAL
      end
      if y == @selected_index
        colr = @selected_color_pair
        attr = @selected_attr
        mark = @selected_mark
      end
      ff = "#{mark} #{f}"
      if ff.size > width
        ff = ff[0...width]
      end

      win.printstring(ctr + r, coffset+c, filler, colr )
      win.printstring(ctr + r, coffset+c, ff, colr, attr)
      ctr += 1 
      @pstart = st
      break if ctr >= ht #-border_offset
    }
    # wmove won't work since form does this after repaint
    #win.wmove( curpos+r , coffset+c) # +1 depends on offset of ctr 
    #setformrowcol( curpos+r , coffset+c)  # TODO is this the right place. NOPE THIS IS GRABBING CURSOR XXX
    # 2018-03-21 - commenting off so we don't call form. trying out.
    #setformrowcol( curpos+r , coffset+c)  if @focussed
    @row_offset = curpos + border_offset
    @col_offset = coffset # this way form can pick it up
    @repaint_required = false
    #win.wrefresh
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
  end

  # listbox key handling
  # preferably move this to mappings, so caller can bind keys to methods TODO
  def handle_key ch
    old_current_index = @current_index
    pagecols = @height/2  # fix these to be perhaps half and one of ht
    spacecols = @height
    case ch
    when FFI::NCurses::KEY_UP, ?k.getbyte(0)
      @current_index -=1
    when FFI::NCurses::KEY_DOWN, ?j.getbyte(0)
      @current_index +=1
    when ?g.getbyte(0)
      @current_index = 0
    when ?G.getbyte(0)
      @current_index = @list.size-1
    when FFI::NCurses::KEY_CTRL_N
      # why are these paging ones not reflecing immediately ?
      @current_index += pagecols
    when FFI::NCurses::KEY_CTRL_P
      @current_index -= pagecols
    when @selection_key
      @repaint_required = true  
      if @selected_index == @current_index 
        @selected_index = nil
      else
        @selected_index = @current_index 
      end
    when FFI::NCurses::KEY_BACKSPACE, 127, FFI::NCurses::KEY_CTRL_B
      @current_index -= spacecols
    when FFI::NCurses::KEY_CTRL_D
      @current_index += spacecols
    else
      ret = super
      return ret
    end
    @current_index = 0 if @current_index < 0
    @current_index = @list.size-1 if @current_index >= @list.size
    @repaint_required = true  if @current_index != old_current_index
  end

  def print_border row, col, height, width, color, att=FFI::NCurses::A_NORMAL
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
