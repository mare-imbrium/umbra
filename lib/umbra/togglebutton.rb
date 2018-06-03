require 'umbra/button'
##
# ----------------------------------------------------------------------------- #
#         File: togglebutton.rb
#  Description: a button that has two states, on and off
#       Author: j kepler  http://github.com/mare-imbrium/umbra/
#         Date: 2018-03-17 - 22:50
#      License: MIT
#  Last update: 2018-06-03 09:33
# ----------------------------------------------------------------------------- #
#  togglebutton.rb Copyright (C) 2018 j kepler
#
#
module Umbra

  # A button that may be switched off an on. 
  # Extended by `RadioButton` and `Checkbox`.
  # WARNING, pls do not override +text+ otherwise checkboxes etc will stop functioning.
  # TODO: add editable here and prevent toggling if not so.
  class ToggleButton < Button 

    # set or get text to display for on value and off value
    attr_accessor :onvalue, :offvalue

    # @param value [true, false] Which value to use currently, onvalue or offvalue
    # @return [true, false] current value
    attr_property :value

    # background to use when selected, if not set then default
    # 2018-04-02 - unused so commenting off. color_pair is not used here or in checkbox
    #attr_property :selected_color_pair

    ## Just calls super.
    ## @param config [Hash] config values such as row, col, onvalue, offvalue and value.
    def initialize config={}, &block
      super

    end

    # @return [onvalue, offvalue] returns on or off value depending on +@value+.
    def getvalue
      @value ? @onvalue : @offvalue
    end

    # WARNING, pls do not override +text+ otherwise checkboxes etc will stop functioning.

    # added for some standardization 2010-09-07 20:28 
    # alias :text :getvalue # NEXT VERSION
    # change existing text to label
    
   
    ##
    # is the button on or off
    # @return [true, false] returns +@value+, has the button been checked or not.
    def checked?
      @value
    end
    alias :selected? :checked?

    def getvalue_for_paint
      # when the width is set externally then the surround chars sit outside the width
      #unless @width
      if @onvalue && @offvalue
        @width = [ @onvalue.length, @offvalue.length ].max 
      end
      #end
      buttontext = getvalue().center(@width)
      @text_offset = @surround_chars[0].length
      @surround_chars[0] + buttontext + @surround_chars[1]
    end

    # toggle button handle key. Handles only `space` (32), all others are passed to parent classes.
    # @param ch [Integer] key received
    #
    def handle_key ch
      if ch == 32
        toggle
        @repaint_required = true # need to change the label
      else
        super
      end
    end

    ##
    # toggle the button value. Calls +fire+.
    def toggle
      fire
    end

    # Toggles the button's value.
    # Called by +toggle+ (when users pressed +SPACE+).
    # Calls :PRESS event
    def fire
      checked(!@value)
      #@item_event = ItemEvent.new self, self if @item_event.nil?
      #@item_event.set(@value ? :SELECTED : :DESELECTED)
      #fire_handler :PRESS, @item_event # should the event itself be ITEM_EVENT
      ## 2018-05-27 - trying to use self in most cases. Above was not needed.
      fire_handler :PRESS, self
    end


    # set the value to true or false
    # user may programmatically want to check or uncheck
    # ## duplicate of value ??? 2018-05-26 - 
    def checked tf
      @value = tf
      @repaint_required = true
    end
  end # class 
end # module
