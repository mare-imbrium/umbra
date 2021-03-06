# ----------------------------------------------------------------------------- #
#         File: button.rb
#  Description: button widget that has an action associated with :PRESS event
#     which by default is the SPACE key.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-16 
#      License: MIT
#  Last update: 2018-06-02 19:28
# ----------------------------------------------------------------------------- #
#  button.rb  Copyright (C) 2012-2018 j kepler
#  == Todo 
#  - mnemonics with highlighting
#  - default button
require 'umbra/widget'
#  ----------------
module Umbra


  ## Widget that has an action associated with `:PRESS` event.
  class Button < Widget 
    attr_accessor :surround_chars   # characters to use to surround the button, def is square brackets

    # char to be underlined, and bound to Alt-char
    attr_accessor :mnemonic


    def initialize config={}, &block
      @focusable = true
      @editable = false
      @highlight_attr = REVERSE
      
      register_events([:PRESS])
      @default_chars = ['> ', ' <'] # a default button is painted differently. UNUSED. ???
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
        #$log.debug "XXX: button #{text}   STATE is #{@state} color #{_color} , attr:#{_attr}"
        value = getvalue_for_paint
        #$log.debug("button repaint :#{self} r:#{r} c:#{c} col:#{_color} v: #{value} ul #{@underline} mnem #{@mnemonic} ")
        #len = @width || value.length # 2018-04-07 - width is not serving a purpose right now
        #                             # since surround chars still come where they do, and only highlight uses the width
        #                             which looks wrong.
        len = value.length
        @graphic.printstring r, c, "%-*s" % [len, value], _color, _attr

        # if a mnemonic character has been defined, then locate the index and highlight it.
        # TODO a mnemonic can also be defined in the text with an ampersand.
        if @mnemonic
          index = value.index(@mnemonic) || value.index(@mnemonic.swapcase)
          if index
            y = c + index
            x = r
            @graphic.mvchgat(x, y, max=1, FFI::NCurses::A_BOLD|UNDERLINE, FFI::NCurses.COLOR_PAIR(_color || 1), nil)
          end
        end
        @repaint_required = false
    end

    ## fires `PRESS` event of button
    def fire
      fire_handler :PRESS, ActionEvent.new(self, :PRESS, text)
    end

    # for campatibility with all buttons, will apply to radio buttons mostly
    # @return [false]
    def selected?; false; end

    def map_keys
      return if @keys_mapped
      bind_key(32, "fire") { fire } if respond_to? :fire
    end

    # Button's key handler, just calls super
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
