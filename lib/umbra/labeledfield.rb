# ----------------------------------------------------------------------------- #
#         File: labeledfield.rb
#  Description: 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-12 - 23:35
#      License: MIT
#  Last update: 2018-04-21 23:58
# ----------------------------------------------------------------------------- #
#  labeledfield.rb Copyright (C) 2018 j kepler
require 'umbra/field'
module Umbra
  # TODO should be able to add a mnemonic here for the label since the association exists
  # TODO we should consider creating a Label, so user can have more control. Or allow user
  #   to supply a Label i/o a String ???
  #
  #   NOTE: If using LabeledField in a messagebox, pls specify messagebox width explicitly
  #   since the width here is the field width, and messagebox has no way of knowing that we are
  #   placing a label too. 

  # Other options:
  #   This could contain a Labal and a Field and extend Widget. Actually, it could be LabeledWidget
  #     so that any other widget is sent in and associated with a a label.
  #
  class LabeledField < Field
    # This stores a +String+ and prints it before the +Field+. 
    # This label is gauranteed to print to the left of the Field.
    # This label prints on +lrow+ and +lcol+ if supplied, else it will print on the left of the field
    # at +col+ minus the width of the label. 
    #
    # It is initialized exactly like a Field, with the addition of label (and optionally label_color_pair,
    #   label_attr, and lcol, lrow)
    # 
    attr_accessor :label              # label of field, just a String  
    # if lrow and lcol are specified then label is printed exactly at that spot.
    # If they are omitted, then label is printed on left of field. Omit the lcol if you want
    #   the fields to be aligned, one under another, with the labels right-aligned.
    attr_accessor :lrow, :lcol        # coordinates of the label
    attr_accessor :label_color_pair   # label of field  color_pair
    attr_accessor :label_attr         # label of field  attribute
    attr_accessor :label_highlight_color_pair   # label of field  high color_pair
    attr_accessor :label_highlight_attr         # label of field  high attribute
    attr_accessor :mnemonic         # mnemonic of field which shows up on label
    attr_accessor :related_widget         #  to keep sync with label
    def initialize config={}, &block
      @related_widget = self
      super
    end

    def repaint
      return unless @repaint_required
      _lrow = @lrow || @row
      # the next was nice, but in some cases this goes out of screen. and the container
      # only sets row and col for whatever is added, it does not know that lcol has to be 
      # taken into account
      _lcol = @lcol || (@col - @label.length  - 2)
      if _lcol < 1
        @lcol = @col
        @col = @lcol + @label.length + 2
        _lcol = @lcol
      end

=begin
      # This actually uses the col of the field, and pushes field ahead. We need to get the above to work.
      unless @lcol
        @lcol = @col
        @col = @lcol + @label.length + 2
      end
      _lcol = @lcol
=end
      lcolor = @label_color_pair || CP_BLACK
      lattr = @label_attr || NORMAL

      # this gives the effect of `pine` (aka alpine)  email client, of highlighting the label
      #   when the field is in focus.
      if @state == :HIGHLIGHTED
        lcolor = @label_highlight_color_pair || lcolor
        lattr = @label_highlight_attr || lattr
      end

      $log.debug "  repaint labeledfield lrow: #{_lrow} lcol #{_lcol} "
      # print the label
      @graphic.printstring _lrow, _lcol, @label, lcolor, lattr
      # print the mnemonic
      if @mnemonic
        index = label.index(@mnemonic) || label.index(@mnemonic.swapcase)
        if index
          y = _lcol + index
          x = _lrow
          @graphic.mvchgat(x, y, max=1, FFI::NCurses::A_BOLD|UNDERLINE, FFI::NCurses.COLOR_PAIR(lcolor || 1), nil)
        end
      end

      # print the field
      super
    end
  end
end # module
