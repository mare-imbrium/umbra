# ----------------------------------------------------------------------------- #
#         File: buttongroup.rb
#  Description: Manages a group of radio buttons
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-02 - 08:47
#      License: MIT
#  Last update: 2018-06-02 10:20
# ----------------------------------------------------------------------------- #
#  buttongroup.rb  Copyright (C) 2012-2018 j kepler
# This is not a visual class or a widget.
# This class allows us to attach several RadioButtons to it, so it can maintain which one is the 
# selected one. It also allows for assigning of commands to be executed whenever a button is pressed,
# akin to binding to the +fire+ of the button, except that one would not have to bind to each button,
# but only once here.
#
# @example
#     group = ButtonGroup.new
#     group.add(r1).add(r2).add(r3)
#     group.command(somelabel) do |grp, label| label.text = grp.value; end
#
module Umbra
class ButtonGroup 

  # Array of buttons that have been added.
  attr_reader    :elements
  # name for group, can be used in messages
  attr_accessor  :name

  # the value of the radio button that is selected. To get the button itself, use +selection+.
  attr_reader :value

  def initialize name="Buttongroup"
    @elements = []
    @hash     = {}
    @name     = name
  end

  # add a radio button to the group.
  def add e
    @elements << e
    @hash[e.value] = e
    e.button_group=(self)
    self
  end
  # remove button from group
  def remove e
    @elements.delete e
    @hash.delete e.value
    self
  end

  # @return the radiobutton that is selected
  def selection
    @hash[@value]
  end

  # @param [String, RadioButton] +value+ of a button, or +Button+ itself to check if selected.
  # @return [true or false] for whether the given value or button is the selected one
  def selected? val
    if val.is_a? String
      @value == val
    else
      @hash[@value] == val
    end
  end
  # install trigger to call whenever a value is updated
  # @public called by user components
  def command *args, &block
    @commands ||= []
    @args ||= []
    @commands << block
    @args << args
  end
  # select the given button or value. 
  # This may be called by user programs to programmatically select a button
  def select button
    if button.is_a? String
      ;
    else
      button = button.value
    end
    self.value = button
  end
  # whenever a radio button is pressed, it updates the value of the group with it;s value.
  # since only one is true at a time.
  def value=(value)
    @value = value
    # 2018-04-02 - need to repaint all the radio buttons so they become off
    @elements.each {|e| e.repaint_required = true }

    return unless @commands
    @commands.each_with_index do |comm, ix|
      comm.call(self, *@args[ix]) unless comm.nil?
    end
  end

end 
end  # module
