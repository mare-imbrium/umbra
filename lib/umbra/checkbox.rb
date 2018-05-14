# ----------------------------------------------------------------------------- #
#         File: checkbox.rb
#  Description: 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-01 - 16:08
#      License: MIT
#  Last update: 2018-05-14 14:34
# ----------------------------------------------------------------------------- #
#  checkbox.rb  Copyright (C) 2012-2018 j kepler
module Umbra
  ##
  # A checkbox, may be selected or unselected
  #
  class Checkbox < ToggleButton 
    attr_property :align_right    # the button will be on the right 2008-12-09 23:41 
    # if a variable has been defined, off and on value will be set in it (default 0,1)
    def initialize config={}, &block
      @surround_chars = ['[', ']']    # 2008-12-23 23:16 added space in Button so overriding
      super
    end
    def getvalue
      @value 
    end
      
    def getvalue_for_paint
      buttontext = getvalue() ? "X" : " "
      dtext = @width.nil? ? @text : "%-*s" % [@width, @text]
      dtext = "" if @text.nil?  # added 2009-01-13 00:41 since cbcellrenderer prints no text
      if @align_right
        @text_offset = 0
        @col_offset = dtext.length + @surround_chars[0].length + 1
        return "#{dtext} " + @surround_chars[0] + buttontext + @surround_chars[1] 
      else
        pretext = @surround_chars[0] + buttontext + @surround_chars[1] 
        @text_offset = pretext.length + 1
        @col_offset = @surround_chars[0].length
        #@surround_chars[0] + buttontext + @surround_chars[1] + " #{@text}"
        return pretext + " #{dtext}"
      end
    end
  end # class 
end # module
