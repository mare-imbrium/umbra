# ----------------------------------------------------------------------------- #
#         File: box.rb
#  Description: a box or border around a container
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-07
#      License: MIT
#  Last update: 2018-06-03 14:50
# ----------------------------------------------------------------------------- #
#  box.rb  Copyright (C) 2018 j kepler
module Umbra
  ##
  # A box is a container around one, or more, widgets.
  # Properties include `visible,` `justify` and `title.`
  # It is not focusable, so no keys can be mapped to it.
  #
  ## FIXME box needs to resize components if it's dimensions are changed.
  ## Or should components have a link to parent, so they can resize themselves ?
  #
  class Box < Widget 
    # @param title [String] set and return title of box
    attr_property :title
    # @param visible [true, false] set and return border visibility
    attr_property :visible        # Is the border visible or not
    # @return [Array<Widget>] return widgets added to this box
    attr_reader   :widgets        # widgets added to this box
    # @return [Widget] return widget added to this box
    attr_reader   :widget         # single widget component
    # @param justify [Symbol] set and return alignment of box :right :left :center
    attr_property :justify       

    def initialize config={}, &block
      @focusable  = false
      @visible    = true
      super
    
      @int_height = self.height - 2
   
      @int_width  = self.width  - 2
      @hlines = []
      #@vlines = []   # UNUSED. TODO ???
    end

    # paint border and title, called by +Form+.
    def repaint                                           #:nodoc:
      return unless @visible
      print_border self.row, self.col, self.height, self.width, @color_pair || CP_BLACK, @attr || NORMAL
      print_title @title
      if !@hlines.empty?
        @hlines.each {|e| hline(e.first, e[1]) }
      end
      # what about asking for painting of widgets
    end

    ## 
    ## Add a variable list of components to a box, which are stacked horizontally by the box.
    ## @param w [Array<Widget>]  comma separated list of widgets
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
    alias :stack :add


    ##
    ##  Horizontally place an array of widgets 
    ## @param w [Array<Widget>] comma separated list of widgets
    ## @note  this is best used for widgets that can be resized.
    # Prefer not to use for buttons since the looks gets messed (inconsistency between button and highlight).
    # Therefore now, button calculates its own width which means that this program cannot determine what the width is
    # and thus cannot center it.
    def flow *w
      @widgets = w
      num = w.size
      wid = (@int_width / num).floor    ## FIXME how to recalc this if RESIZE
      ht  = @int_height 
      srow = self.row + 1
      scol = self.col + 1
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


    ## Fill out a single widget into the entire box leaving an inset of 1.
    ## @param [Widget]
    # NOTE: use if only one widget will expand into this box
    def fill w
      # should have been nice if I could add widget to form, but then order might get wrong
      w.row = self.row + 1
      w.col = self.col + 1
      if w.respond_to? :width
        if @width < 0
          w.width = @width - 1   ## relative to bottom
        else
          w.width = @width - 2   ## absolute
        end
      end
      if w.respond_to? :height
        if @height < 0
          w.height = @height - 1   ## relative to bottom
        else
          w.height = @height - 2   ## absolute
        end
      end
      @widget = w
    end

    ## Paint a horizontal line, as a separator between widgets
    ## Called by `repaint`.
    ## @param row [Integer] row
    ## @param col [Integer] column
    def hline row, col
      return if row >= self.row + self.height
      $log.debug "  hline: #{row} ... #{@row}   #{@height}  "
      FFI::NCurses.mvwhline( @graphic.pointer, row, col, FFI::NCurses::ACS_HLINE, self.width()-2)
    end

    # print a title over the box on zeroth row
    private def print_title stitle
      return unless stitle
      stitle = "| #{stitle} |"
      @justify ||= :center
      col = case @justify
      when :left
        4
      when :right
        self.width -stitle.size - 3
      else
        (self.width-stitle.size)/2
      end
      #FFI::NCurses.mvwaddstr(@pointer, 0, col, stitle) 
      @graphic.printstring(self.row, col, stitle)
    end

    private def print_border row, col, height, width, color, att=FFI::NCurses::A_NORMAL
      $log.debug "  PRINTING border with #{row} #{col} #{height} #{width} INSIDE BOX"
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
