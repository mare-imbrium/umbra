# ----------------------------------------------------------------------------- #
#         File: button.rb
#  Description: button widget that has an action associated with :PRESS event
#     which by default is the SPACE key.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-16 
#      License: MIT
#  Last update: 2018-04-01 09:36
# ----------------------------------------------------------------------------- #
#  button.rb  Copyright (C) 2012-2018 j kepler
#  == TODO 
#  - mnemonics with highlighting
#  - default button
require 'umbra/widget'
#  ----------------
module Umbra
  class Button < Widget 
    attr_accessor :surround_chars   # characters to use to surround the button, def is square brackets
    # char to be underlined, and bound to Alt-char
    attr_accessor :mnemonic
    def initialize config={}, &block
      @focusable = true
      @editable = false
      @highlight_attr = REVERSE
      # hotkey denotes we should bind the key itself not alt-key (for menulinks)
      #@hotkey = config.delete(:hotkey)  2018-03-22 - 
      # 2018-03-18 - FORM_ATTACHED deprecated to keep things simple
      register_events([:PRESS, :FORM_ATTACHED])
      @default_chars = ['> ', ' <'] # a default button is painted differently
      super


      @surround_chars ||= ['[ ', ' ]'] 
      @col_offset = @surround_chars[0].length 
      @text_offset = 0      # used to determine where underline should fall TODO ???
      map_keys
    end
    ##
    # set button based on Action
    # 2018-03-22 - is this still used ?
    # This allows action objects to be used in multiple places such as buttons, menus, popups etc.
    def action a
      text a.name
      mnemonic a.mnemonic unless a.mnemonic.nil?
      command { a.call }
    end

    def getvalue
      @text
    end

    # ensure text has been passed or action
    def getvalue_for_paint
      ret = getvalue
      @text_offset = @surround_chars[0].length
      @surround_chars[0] + ret + @surround_chars[1]
    end

    def repaint  # button
      return unless @repaint_required

        $log.debug("BUTTON repaint : #{self}  r:#{@row} c:#{@col} , cp:#{@color_pair}, st:#{@state}, #{getvalue_for_paint}" )
        r,c = @row, @col 
        _attr = @attr || NORMAL
        _color = @color_pair
        if @state == :HIGHLIGHTED
          _color = @highlight_color_pair || @color_pair
          _attr = @highlight_attr || _attr
        elsif selected? # only for certain buttons lie toggle and radio
          _color = @selected_color_pair || @color_pair
        end
        $log.debug "XXX: button #{text}   STATE is #{@state} color #{_color} , attr:#{_attr}"
        value = getvalue_for_paint
        #$log.debug("button repaint :#{self} r:#{r} c:#{c} col:#{_color} v: #{value} ul #{@underline} mnem #{@mnemonic} ")
        len = @width || value.length
        @graphic.printstring r, c, "%-*s" % [len, value], _color, _attr
=begin
#       @form.window.mvchgat(y=r, x=c, max=len, Ncurses::A_NORMAL, bgcolor, nil)
        # in toggle buttons the underline can change as the text toggles
        if @underline || @mnemonic # {{{ TODO
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
        end # }}}
=end
        @repaint_required = false
    end

    ## command of button (invoked on press, hotkey, space)
    # added args 2008-12-20 19:22 
    def command *args, &block
      bind_event :PRESS, *args, &block
    end
    ## fires PRESS event of button
    def fire
      #$log.debug "firing PRESS #{text}"
      fire_handler :PRESS, ActionEvent.new(self, :PRESS, text)
    end
    # for campatibility with all buttons, will apply to radio buttons mostly
    def selected?; false; end

    def map_keys
      return if @keys_mapped
      bind_key(32, "fire") { fire } if respond_to? :fire
    end

    # Button
    def handle_key ch
      super
    end

    # layout an array of buttons horizontally {{{
    def self.button_layout buttons, row, startcol=0, cols=FFI::NCurses.COLS-1, gap=5
      col = startcol
      buttons.each_with_index do |b, ix|
        $log.debug " BUTTON #{b}: #{b.col} "
        b.row = row
        b.col col
        $log.debug " after BUTTON #{b}: #{b.col} "
        len = b.text.length + gap
        col += len
      end
    end
  end #BUTTON # }}}
end # module
