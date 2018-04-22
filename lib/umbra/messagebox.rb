# ----------------------------------------------------------------------------- #
#         File: messagebox.rb
#  Description: a small window with a list or message or fields and buttons which pops up.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-13 - 23:10
#      License: MIT
#  Last update: 2018-04-21 14:44
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2018 j kepler
require 'umbra/window'
require 'umbra/form'
require 'umbra/widget'
require 'umbra/button'
require 'umbra/field'
require 'umbra/label'
require 'umbra/textbox'

module Umbra
  class MessageBox

    attr_reader :form
    attr_reader :window
    attr_accessor :title
    attr_accessor :buttons     # button labels. e.g. [Ok, Cancel]
    #dsl_accessor :default_button
    #
    # a message to be printed, usually this will be the only thing supplied
    # with an OK button. This should be a short string, a label will be used
    # and input_config passed to it

    #dsl_accessor :message
    # you can also set button_orientation : :right, :left, :center
    #
    def initialize config={}, &block

      h = config.fetch(:height, nil)
      w = config.fetch(:width, nil)
      t = config.fetch(:row, nil)
      l = config.fetch(:col, nil)
      if h && w && t && l
        #@window = Window.new :height => h, :width => w, :top => t, :left => l
        @window = Window.new  h, w, t, l
        # else window will be created in repaint, and form will pass it to widgets before their first
        # repaint
      end
      @form = Form.new @window
      @buttons = ["Ok", "Cancel"]

      config.each_pair { |k,v| instance_variable_set("@#{k}",v) }
      @config = config
      @row = 0
      @col = 0
      @row_offset = 1
      @col_offset = 2
      
      #@color ||= :black
      #@bgcolor ||= :white
      @color_pair  = CP_BLACK
      # 2014-05-31 - 11:44 adding form color 
      #   try not to set buttons color in this program, let button pick up user or form colors
      #@form.color = @color
      #@form.bgcolor = @bgcolor
      #@form.color_pair = @color_pair
      @maxrow = 3

      instance_eval &block if block_given?
      #yield_or_eval &block if block_given? TODO

    end
    def item widget
      # # normalcolor gives a white on black stark title like links and elinks
      # You can also do 'acolor' to give you a sober title that does not take attention away, like mc
      # remove from existing form if set, problem with this is mnemonics -- rare situation.
      #if widget.form
        #f = widget.form
        #f.remove_widget widget
      #end
      @maxrow ||= 3
      #widget.set_form @form
      @form.add_widget widget
      widget.row ||= 0
      widget.col ||= 0
      if widget.row == 0
        widget.row = [@maxrow+1, 3].max if widget.row == 0
      else
        widget.row += @row_offset 
      end
      if widget.col == 0
        widget.col = 5
      else
        # i don't know button_offset as yet
        widget.col += @col_offset 
      end
      # in most cases this override is okay, but what if user has set it
      # The problem is that widget and field are doing a default setting so i don't know
      # if user has set or widget has done a default setting. NOTE
      # 2014-05-31 - 12:40 CANIS BUTTONCOLOR i have commented out since it should take from form
      #   to see effect
      if false
        widget.color ||= @color    # we are overriding colors, how to avoid since widget sets it
        widget.bgcolor  ||= @bgcolor
        widget.attr = @attr if @attr # we are overriding what user has put. DARN !
      end
      @maxrow = widget.row if widget.row > @maxrow
      @suggested_h = @height || @maxrow+6
      @suggested_w ||= 0
      ww = widget.width || 5  # some widgets do no set a default width, and could be null
      _w = [ww + 5, 15].max
      @suggested_w = widget.col + _w if widget.col > @suggested_w
      if ww >= @suggested_w
        @suggested_w = ww + widget.col + 10
      end
      $log.debug "  MESSAGEBOX add suggested_w #{@suggested_w} "
      # if w's given col is > width then add to suggested_w or text.length
    end
    alias :add :item
    # returns button index
    # Call this after instantiating the window
    def run
      repaint
      @form.pack # needs window
      @form.repaint
      @window.wrefresh
      return handle_keys
    end
    def repaint
      _create_window unless @window
      #acolor = get_color $reverscolor, @color, @bgcolor 
      acolor = 0 # ??? FIXME
      $log.debug " MESSAGE BOX bg:#{@bgcolor} , co:#{@color} , colorpair:#{acolor}"
      @window.wbkgd(FFI::NCurses.COLOR_PAIR(acolor) | REVERSE); 

      @color_pair ||= CP_BLACK
      bordercolor = @border_color || CP_BLACK
      borderatt = @border_attrib || NORMAL
      @window.wattron(FFI::NCurses.COLOR_PAIR(bordercolor) | (borderatt || FFI::NCurses::A_NORMAL))
      print_border_mb @window, 1,2, @height, @width, nil, nil
      @window.wattroff(FFI::NCurses.COLOR_PAIR(bordercolor) | (borderatt || FFI::NCurses::A_NORMAL))
      @title ||= "+-+"
      @title_color ||= CP_CYAN
      @title_attr ||= REVERSE
      title = " "+@title+" "
      # normalcolor gives a white on black stark title like links and elinks
      # You can also do 'acolor' to give you a sober title that does not take attention away, like mc
      @window.printstring(@row=1,@col=(@width-title.length)/2,title, color=@title_color, @title_attr)
      #print_message if @message
      create_action_buttons(*@buttons) unless @action_buttons
    end
    def create_action_buttons *labels
      @action_buttons = []
      _row = @height-3
      _col = (@width-(labels.count*8))/2
      _col = 5 if _col < 1

      labels.each_with_index do |l, ix|
        b = Button.new text: l, row: _row, col: _col
        _col += l.length+5
        @action_buttons << b
        @form.add_widget b
        b.command do
          @selected_index = ix
          throw(:close, ix)
        end
      end
    end
    # CLEAN THIS UP TODO
    # Pass a short message to be printed. 
    # This creates a label for a short message, and a field for a long one.
    # @yield field created
    # @param [String] text to display
    def message message # yield label or field being used for display for further customization
      @suggested_h = @height || 10
      message = message.gsub(/[\n\r\t]/,' ') rescue message
      message_col = 5
      $log.debug "  MESSAGE w: #{@width}, size: #{message.size} "
      _pad = 5
      @suggested_w = @width || [message.size + _pad + message_col , FFI::NCurses.COLS-2].min
      r = 3
      len = message.length
      #@suggested_w = len + _pad + message_col if len < @suggested_w - _pad - message_col

      display_length = @suggested_w-_pad
      display_length -= message_col
      message_height = 2
      #clr = @color || :white
      #bgclr = @bgcolor || :black

      color_pair = CP_WHITE
      # trying this out. sometimes very long labels get truncated, so i give a field in wchich user
      # can use arrow key or C-a and C-e
      if message.size > display_length
        message_label = Field.new({:text => message, :name=>"message_label",
          :row => r, :col => message_col, :width => display_length,  
          :color_pair => color_pair, :editable => false})
      else
        message_label = Label.new({:text => message, :name=>"message_label",
          :row => r, :col => message_col, :width => display_length,
          :height => message_height, :color_pair => color_pair})
      end
      @form.add_widget message_label
      @maxrow = 3
      yield message_label if block_given?
    end
    alias :message= :message
 
    # This is for larger messages, or messages where the size is not known.
    # A textview object is created and yielded.
    #
    def text message
      @suggested_w = @width || (FFI::NCurses.COLS * 0.80).floor
      @suggested_h = @height || (FFI::NCurses.LINES * 0.80).floor

      message_col = 3
      r = 2
      display_length = @suggested_w-4
      display_length -= message_col
      #clr = @color || :white
      #bgclr = @bgcolor || :black
      color_pair = CP_WHITE

      if message.is_a? Array
        l = longest_in_list message
        if l > @suggested_w 
          if l < FFI::NCurses.COLS
            #@suggested_w = l
            @suggested_w = FFI::NCurses.COLS-2 
          else
            @suggested_w = FFI::NCurses.COLS-2 
          end
          display_length = @suggested_w-6
        end
        # reduce width and height if you can based on array contents
      else
        message = wrap_text(message, display_length).split("\n")
      end
      # now that we have moved to textpad that +8 was causing black lines to remain after the text
      message_height = message.size #+ 8
      # reduce if possible if its not required.
      #
      r1 = (FFI::NCurses.LINES-@suggested_h)/2
      r1 = r1.floor
      w = @suggested_w
      c1 = (FFI::NCurses.COLS-w)/2
      c1 = c1.floor
      @suggested_row = r1
      @suggested_col = c1
      brow = @button_row || @suggested_h-4
      available_ht = brow - r + 1
      message_height = [message_height, available_ht].min
      # replaced 2014-04-14 - 23:51 
      message_label = Textbox.new({:name=>"message_label", :list => message,
        :row => r, :col => message_col, :width => display_length,
        :height => message_height, :color_pair => color_pair})
      #message_label.set_content message
      @form.add_widget message_label
      yield message_label if block_given?

    end
    alias :text= :text
    # returns length of longest
    def longest_in_list list  #:nodoc:
      longest = list.inject(0) do |memo,word|
        memo >= word.length ? memo : word.length
      end    
      longest
    end    
    def wrap_text(s, width=78)    # {{{
      s.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n").split("\n")
    end
    def _create_window

      $log.debug "  MESSAGEBOX _create_window h:#{@height} w:#{@width} r:#{@row} c:#{@col} "
      $log.debug "  MESSAGEBOX _create_window h:#{@suggested_h} w:#{@suggested_w} "
      @width ||= @suggested_w || 60
      @height = @suggested_h || 10
      $log.debug "  MESSAGEBOX _create_window h:#{@height} w:#{@width} r:#{@row} c:#{@col} "
      if @suggested_row
        @row = @suggested_row
      else
        @row = ((FFI::NCurses.LINES-@height)/2).floor
      end
      if @suggested_col
        @col = @suggested_col
      else
        w = @width
        @col = ((FFI::NCurses.COLS-w)/2).floor
      end
      #@window = Window.new :height => @height, :width => @width, :top => @row, :left => @col
      $log.debug "  MESSAGEBOX _create_window h:#{@height} w:#{@width} r:#{@row} c:#{@col} "
      @window = Window.new  @height,  @width,  @row,  @col
      @graphic = @window
      @form.window = @window
      # in umbra, the widgets would not be having a window, if window was created after the widgets were added
    end
    def handle_keys
      buttonindex = catch(:close) do 
        while((ch = @window.getch()) != FFI::NCurses::KEY_F10 )
          break if ch == ?\C-q.getbyte(0) || ch == 2727 # added double esc
          begin
            # trying out repaint of window also if repaint all asked for. 12 is C-l
            if ch == 1000 or ch == 12
              repaint
            end
            @form.handle_key(ch)
            @window.wrefresh
          rescue => err
            $log.debug( err) if err
            $log.debug(err.backtrace.join("\n")) if err
            #textdialog ["Error in Messagebox: #{err} ", *err.backtrace], :title => "Exception" # TODO
            @window.refresh # otherwise the window keeps showing (new FFI-ncurses issue)
          ensure
          end

        end # while loop
      end # close
      $log.debug "MESSAGEBOX: CALLING PROGRAM BEING RETURNED: #{buttonindex} "
      @window.destroy
      # added 2014-05-01 - 18:10 hopefully to refresh root_window.
      #Window.refresh_all
      return buttonindex 
    end
    # this is identical to the border printed by dialogs.
    # The border is printed not on the edge, but one row and column inside.
    # This is purely cosmetic, otherwise windows.box should be used which prints a box 
    # on the edge.
    private def print_border_mb window, row, col, height, width, color, attr # {{{
      win = window.pointer
      #att = attr
      len = width
      len = FFI::NCurses.COLS if len == 0
      space_char = " ".codepoints.first
      (row-1).upto(row+height-1) do |r|
        # this loop clears the screen, printing spaces does not work since ncurses does not do anything
        FFI::NCurses.mvwhline(win, r, col, space_char, len)
      end

      FFI::NCurses.mvwaddch win, row, col, FFI::NCurses::ACS_ULCORNER
      FFI::NCurses.mvwhline( win, row, col+1, FFI::NCurses::ACS_HLINE, width-6)
      FFI::NCurses.mvwaddch win, row, col+width-5, FFI::NCurses::ACS_URCORNER
      FFI::NCurses.mvwvline( win, row+1, col, FFI::NCurses::ACS_VLINE, height-4)

      FFI::NCurses.mvwaddch win, row+height-3, col, FFI::NCurses::ACS_LLCORNER
      FFI::NCurses.mvwhline(win, row+height-3, col+1, FFI::NCurses::ACS_HLINE, width-6)
      FFI::NCurses.mvwaddch win, row+height-3, col+width-5, FFI::NCurses::ACS_LRCORNER
      FFI::NCurses.mvwvline( win, row+1, col+width-5, FFI::NCurses::ACS_VLINE, height-4)
    end # }}}
  end # class
end # module
