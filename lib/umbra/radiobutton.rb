# ----------------------------------------------------------------------------- #
#         File: radiobutton.rb
#  Description: a member of a group of buttons, only one can be selected at a time.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-02 - 10:37
#      License: MIT
#  Last update: 2018-06-01 12:31
# ----------------------------------------------------------------------------- #
#  radiobutton.rb  Copyright (C) 2012-2018 j kepler

module Umbra
  ##
  # A selectable button that has a text value. It is based on a Variable that
  # is shared by other radio buttons. Only one is selected at a time, unlike checkbox
  # +text+ is the value to display, which can include an ampersand for a hotkey
  # +value+ is the value returned if selected, which usually is similar to text (or a short word)
  # +width+ is helpful if placing the brackets to right of text, used to align round brackets
  #   By default, radio buttons place the button on the left of the text.
  #
  # Typically, the variable's update_command is passed a block to execute whenever any of the 
  # radiobuttons of this group is fired.

  class RadioButton < ToggleButton
    attr_property :align_right    # the button will be on the right 
    attr_accessor :button_group   # group that this button belongs to.

    def initialize config={}, &block
      @surround_chars = ['(', ')'] if @surround_chars.nil?
      super
      $log.warn "XXX: FIXMe Please set 'value' for radiobutton. If not sure, try setting it to the same value as 'text'" unless @value
      @value ||= @text
    end

    # all radio buttons will return the value of the selected value, not the offered value
    def getvalue
      @button_group.value
    end

    def getvalue_for_paint
      buttontext = getvalue() == @value ? "o" : " "
      $log.debug "called get_value_for paint for buttong #{@value} :#{buttontext} "
      dtext = @width.nil? ? text : "%-*s" % [@width, text]
      if @align_right
        @text_offset = 0
        @col_offset = dtext.length + @surround_chars[0].length + 1
        return "#{dtext} " + @surround_chars[0] + buttontext + @surround_chars[1] 
      else
        pretext = @surround_chars[0] + buttontext + @surround_chars[1] 
        @text_offset = pretext.length + 1
        @col_offset = @surround_chars[0].length
        return pretext + " #{dtext}"
      end
    end

    def toggle
      fire
    end

    ##
    # If user has pressed on this then set the group to this button.
    def checked tf

      if @button_group.value == value
        @button_group.value = ""
      else
        @button_group.value = value
      end
    end

  end # class radio 
end # module
