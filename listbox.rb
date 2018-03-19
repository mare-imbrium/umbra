# ----------------------------------------------------------------------------- #
#         File: listbox.rb
#  Description: list widget that displays a list of items
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-19 
#      License: MIT
#  Last update: 2018-03-19 12:18
# ----------------------------------------------------------------------------- #
#  listbox.rb  Copyright (C) 2012-2018 j kepler
#  == TODO 
#  border
#  keys
#  ----------------
class Listbox < Widget 
  attr_reader :list  # list containing data 

  def initialize config={}, &block
    @focusable = true
    @editable = false
    @pstart = 0    # which row does printing start from
    @current_index = 0 # index of row on which cursor is
    #@list = config.fetch(:list)
    register_events([:LEAVE_ROW, :ENTER_ROW, :LIST_SELECTION_EVENT])
    super

    map_keys
  end
  def list=(alist)
    @list = alist
  end

  def repaint 
    win = @graphic
    r,c = @row, @col 
    _attr = @attr || NORMAL
    _color = @color_pair
    curpos = 1
    x = 1
    #width = win.width-1
    width = @width
    files = @list
    
    #ht = win.height-2
    ht = @height
    cur = @current_index
    st = pstart = @pstart           # previous start
    pend = pstart + ht -1 # previous end
    if cur > pend
      st = (cur -ht) +1
    elsif cur < pstart
      st = cur
    end
    hl = cur
    y = 0
    ctr = 0
    filler = " "*width
    files.each_with_index {|f, y| 
      next if y < st
      colr = CP_WHITE # white on bg -1
      ctr += 1
      mark = " "
      if y == hl
        attr = FFI::NCurses::A_REVERSE
        mark = ">"
        curpos = ctr
      else
        attr = FFI::NCurses::A_NORMAL
      end
      ff = "#{mark} #{f}"

      win.printstring(ctr + r, x+c, filler, colr )
      win.printstring(ctr + r, x+c, ff, colr, attr)
      break if ctr >= ht
    }
    #win.wmove( curpos , 0) # +1 depends on offset of ctr 
    win.wrefresh
  end

  def getvalue
    @list
  end

  # ensure text has been passed or action
  def getvalue_for_paint
    raise
    ret = getvalue
    @text_offset = @surround_chars[0].length
    @surround_chars[0] + ret + @surround_chars[1]
  end

  # FIXME 2014-05-31 since form checks for highlight color and sets repaint on on_enter, we shoul not set it.
  #   but what if it is set at form level ?
  #    also it is not correct to set colors now that form's defaults are taken
  def OLDrepaint  # button

    $log.debug("BUTTON repaint : #{self}  r:#{@row} c:#{@col} , cp:#{@color_pair}, st:#{@state}, #{getvalue_for_paint}" )
    r,c = @row, @col 
    _attr = @attr || NORMAL
    _color = @color_pair
    if @state == :HIGHLIGHTED
      _color = @highlight_color_pair || @color_pair
      _attr = REVERSE #if _color == @color_pair
    elsif selected? # only for certain buttons lie toggle and radio
      _color = @selected_color_pair || @color_pair
    end
    $log.debug "XXX: button #{text}   STATE is #{@state} color #{_color} , attr:#{_attr}"
    value = getvalue_for_paint
    $log.debug("button repaint :#{self} r:#{r} c:#{c} col:#{_color} v: #{value} ul #{@underline} mnem #{@mnemonic} ")
    len = @width || value.length
    @graphic = @form.window if @graphic.nil? ## cell editor listbox hack 
    @graphic.printstring r, c, "%-*s" % [len, value], _color, _attr
    #       @form.window.mvchgat(y=r, x=c, max=len, Ncurses::A_NORMAL, bgcolor, nil)
    # in toggle buttons the underline can change as the text toggles
    if @underline || @mnemonic
      uline = @underline && (@underline + @text_offset) ||  value.index(@mnemonic) || 
        value.index(@mnemonic.swapcase)
      # if the char is not found don't print it
      if uline
        y=r #-@graphic.top
        x=c+uline #-@graphic.left
        #
        # NOTE: often values go below zero since root windows are defined 
        # with 0 w and h, and then i might use that value for calcaluting
        #
        $log.error "XXX button underline location error #{x} , #{y} " if x < 0 or c < 0
        raise " #{r} #{c}  #{uline} button underline location error x:#{x} , y:#{y}. left #{@graphic.left} top:#{@graphic.top} " if x < 0 or c < 0
        @graphic.mvchgat(y, x, max=1, Ncurses::A_BOLD|Ncurses::A_UNDERLINE, _color, nil)
      end
    end
  end


  def map_keys
    return if @keys_mapped
  end

  # listbox key handling
  # TODO selection
  # goes off above and below FIXME
  def handle_key ch
    @repaint_required = true 
    pagecols = 20
    spacecols = 30
    case ch
    when FFI::NCurses::KEY_UP
      @current_index -=1
    when FFI::NCurses::KEY_DOWN
      @current_index +=1
    when FFI::NCurses::KEY_CTRL_N
      @current_index += pagecols
    when FFI::NCurses::KEY_CTRL_P
      @current_index -= pagecols
    when 32
      @current_index += spacecols
    when FFI::NCurses::KEY_BACKSPACE, 127
      @current_index -= spacecols
    super
    end
  end

end 
