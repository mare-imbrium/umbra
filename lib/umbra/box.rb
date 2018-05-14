# ----------------------------------------------------------------------------- #
#         File: box.rb
#  Description: a box or border around a container
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-07
#      License: MIT
#  Last update: 2018-05-14 15:05
# ----------------------------------------------------------------------------- #
#  box.rb  Copyright (C) 2018 j kepler
module Umbra
  ##
  # A box is a container around one, maybe more, widgets.
  #
  class Box < Widget 
    attr_property :title
    attr_property :width
    attr_property :height
    attr_accessor :row_offset     # not used yet
    attr_accessor :col_offset     # not used yet
    attr_property :visible
    attr_reader   :widgets
    attr_reader   :widget
    attr_property :justify       # right, left or center TODO

    def initialize config={}, &block
      @focusable  = false
      @visible    = true
      super
      @int_height = @height - 2
      @int_width  = @width  - 2
      @hlines = []
      @vlines = []
    end
    def repaint
      return unless @visible
      print_border @row, @col, @height, @width, @color_pair || CP_BLACK, @attr || NORMAL
      print_title @title
      if !@hlines.empty?
        @hlines.each {|e| hline(e.first, e[1]) }
      end
      # what about asking for painting of widgets
    end
    # should we take in an array and apportion them 
    # since we are keeping a row in between as divider, need to adjust heights.
    # Depending on how many components
    def add *w
      @widgets = w
      num = w.size
      wid = @int_width 
      ht  = (@int_height / num)
      srow = @row + 1
      scol = @col + 1
      w.each_with_index do |e, ix|
        e.width = wid
        e.height = ht 
        e.row    = srow
        e.col    = scol
        srow += ht + 1
        @hlines << [ srow-1, scol ]
      end
      # FIXME there will be one additional hline in the end.
      w[-1].height -= (num-1)
    end
    # this is best used for widgets that can be resized.
    # Prefer not to use for buttons since the looks gets messed (inconsistency betwewn button and highlight).
    # Therefore now, button calculates its own width which means that this program cannot determine what the width is
    # and thus cannot center it.
    def flow *w
      @widgets = w
      num = w.size
      wid = (@int_width / num).floor
      ht  = @int_height 
      srow = @row + 1
      scol = @col + 1
      w.each_with_index do |e, ix|
        # unfortunately this is messing with button width calculation
        # maybe field and button should have resizable or expandable ?
        e.width = wid unless e.width
        e.height = ht 
        e.row    = srow
        e.col    = scol
        scol += wid + 1
        #@hlines << [ srow-1, scol ]
      end
      # FIXME there will be one additional hline in the end.
      # we added 1 to the scol each time, so decrement
      w[-1].width -= (num-1)
    end
    # use if only one widget will expand into this box
    def fill w
      # should have been nice if I could add widget to form, but then order might get wrong
      w.row = @row + 1
      w.col = @col + 1
      w.width = @width - 2 if w.respond_to? :width
      w.height = @height - 2 if w.respond_to? :height
      @widget = w
    end
    def hline row, col
      return if row >= @row + @height
      $log.debug "  hline: #{row} ... #{@row}   #{@height}  "
      FFI::NCurses.mvwhline( @graphic.pointer, row, col, FFI::NCurses::ACS_HLINE, @width-2)
    end

    # print a title over the box on zeroth row
    # TODO right or  left or center align
    private def print_title stitle
      return unless stitle
      stitle = "| #{stitle} |"
      @justify ||= :center
      col = case @justify
      when :left
        4
      when :right
        @width -stitle.size - 3
      else
        (@width-stitle.size)/2
      end
      #FFI::NCurses.mvwaddstr(@pointer, 0, col, stitle) 
      @graphic.printstring(@row, col, stitle)
    end

    private def print_border row, col, height, width, color, att=FFI::NCurses::A_NORMAL
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
  end # class 
end # module
