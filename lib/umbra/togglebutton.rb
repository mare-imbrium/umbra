require 'umbra/button'
##
# ----------------------------------------------------------------------------- #
#         File: togglebutton.rb
#  Description: a button that has two states, on and off
#       Author: j kepler  http://github.com/mare-imbrium/umbra/
#         Date: 2018-03-17 - 22:50
#      License: MIT
#  Last update: 2018-05-02 14:44
# ----------------------------------------------------------------------------- #
#  togglebutton.rb Copyright (C) 2012-2018 j kepler
#
#
module Umbra
  ##
  # an event fired when an item that can be selected is toggled/selected
  class ItemEvent  # {{{
    # http://java.sun.com/javase/6/docs/api/java/awt/event/ItemEvent.html
    attr_reader :state   # :SELECTED :DESELECTED
    attr_reader :item   # the item pressed such as toggle button
    attr_reader :item_selectable   # item originating event such as list or collection
    attr_reader :item_first   # if from a list
    attr_reader :item_last   # 
    attr_reader :param_string   #  for debugging etc
=begin
    def initialize item, item_selectable, state, item_first=-1, item_last=-1, paramstring=nil
      @item, @item_selectable, @state, @item_first, @item_last =
        item, item_selectable, state, item_first, item_last 
      @param_string = "Item event fired: #{item}, #{state}"
    end
=end
    # i think only one is needed per object, so create once only
    def initialize item, item_selectable
      @item, @item_selectable =
        item, item_selectable
    end
    def set state, item_first=-1, item_last=-1, param_string=nil
      @state, @item_first, @item_last, @param_string =
        state, item_first, item_last, param_string 
      @param_string = "Item event fired: #{item}, #{state}" if param_string.nil?
    end
  end # }}}
# A button that may be switched off an on. 
# Extended by RadioButton and checkbox.
# WARNING, pls do not override +text+ otherwise checkboxes etc will stop functioning.
# TODO: add editable here nd prevent toggling if not so.
class ToggleButton < Button 
  # text for on value and off value
  attr_accessor :onvalue, :offvalue
  # boolean, which value to use currently, onvalue or offvalue
  attr_accessor :value
  # characters to use for surround, array, default square brackets
  attr_accessor :surround_chars 
  # 2018-04-02 - removing variable
  #attr_accessor :variable    # value linked to this variable which is a boolean
  # background to use when selected, if not set then default
  # 2018-04-02 - unused so commenting off. color_pair is not used here or in checkbox
  #attr_accessor :selected_bgcolor
  #attr_accessor :selected_color 
  attr_property :selected_color_pair

  def initialize config={}, &block
    super

    #@value ||= (@variable.nil? ? false : @variable.get_value(@name)==true)
    # TODO may need to do this when this is added to button_group 
  end
  def getvalue
    @value ? @onvalue : @offvalue
  end

  # WARNING, pls do not override +text+ otherwise checkboxes etc will stop functioning.

  # added for some standardization 2010-09-07 20:28 
  # alias :text :getvalue # NEXT VERSION
  # change existing text to label
  ##
  # is the button on or off
  # added 2008-12-09 19:05 
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

  # toggle button handle key
  # @param [int] key received
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
  # toggle the button value
  def toggle
    fire
  end

  # called on :PRESS event
  # caller should check state of itemevent passed to block
  # NOTE i have not brought ItemEvent in here.
  def fire
    checked(!@value)
    @item_event = ItemEvent.new self, self if @item_event.nil?
    @item_event.set(@value ? :SELECTED : :DESELECTED)
    fire_handler :PRESS, @item_event # should the event itself be ITEM_EVENT
  end
  ##
  # set the value to true or false
  # user may programmatically want to check or uncheck
  def checked tf
    @value = tf
=begin
    if @variable
      if @value 
        @variable.set_value((@onvalue || 1), @name)
      else
        @variable.set_value((@offvalue || 0), @name)
      end
    end
=end
  end
end # class 
end # module
