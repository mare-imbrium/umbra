# ----------------------------------------------------------------------------- #
#         File: label.rb
#  Description: an ncurses label
#               The preferred way of printing text on screen, esp if you want to modify it at run time.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-08 - 14:04
#      License: MIT
#  Last update: 2018-05-22 11:01
# ----------------------------------------------------------------------------- #
#  label.rb  Copyright (C) 2018- j kepler
#
require 'umbra/widget'
module Umbra
  # a text label. 
  # when creating use +text=+ to set text. Optionally use +justify+ and +width+.
class Label < Widget 

  # justify required a display length, esp if center.
  attr_property   :justify        #:right, :left, :center
  attr_accessor   :mnemonic       # alt-key that passes focus to related field 
  attr_accessor   :related_widget # field related to this label. See +mnemonic+.

  def initialize config={}, &block

    @text = config.fetch(:text, "NOTFOUND")
    @editable = false
    @focusable = false
    # we have some processing for when a form is attached, registering a hotkey
    #register_events :FORM_ATTACHED
    super
    @justify ||= :left
    @name ||= @text
    @width ||= @text.length # 2018-04-14 - added for messageboxes
    @repaint_required = true
  end
  #
  # get the value for the label
  def getvalue
    @text
  end


  ##
  # NOTE: width can be nil, i have not set a default, containers asking width can crash. WHY NOT ?
  def repaint
    return unless @repaint_required
    raise "Label row or col is nil #{@row} , #{@col}, #{@text} " if @row.nil? || @col.nil?
    #r,c = rowcol
    r = self.row
    c = self.col
    $log.debug "label repaint #{r} #{c} #{@text} "

    # value often nil so putting blank, but usually some application error
    value = getvalue_for_paint || ""

    if value.is_a? Array
      value = value.join " "
    end
    # ensure we do not exceed
    # ## TODO do this in the format commented on 2018-05-22 - 
    _width = self.width
    #if _width
      #if value.length > _width
        #value = value[0.._width-1]
      #end
    #end
    len = _width || value.length
    acolor = @color_pair  || 0
    #str = @justify.to_sym == :right ? "%*s" : "%-*s"  # added 2008-12-22 19:05 
    str = @justify.to_sym == :right ? "%#{len}.#{len}s" : "%-#{len}.#{len}s"  # added 2008-12-22 19:05 

    # clear the area
    @graphic.printstring r, c, " " * len , acolor, @attr
    if @justify.to_sym == :center
      padding = (_width - value.length)/2
      value = " "*padding + value + " "*padding # so its cleared if we change it midway
    end
    ## move this into paint_label or something so we can override.
    # try a block which was passed earlier which gets a string TODO
    @graphic.printstring r, c, str % [value], acolor, @attr
    if @mnemonic
      ulindex = value.index(@mnemonic) || value.index(@mnemonic.swapcase)
      @graphic.mvchgat(y=r, x=c+ulindex, max=1, BOLD|UNDERLINE, acolor, nil)
    end
    @repaint_required = false
  end
  # Added 2011-10-22 to prevent some naive components from putting focus here.
  def on_enter
    raise "Cannot enter Label"
  end
  def on_leave
    raise "Cannot leave Label"
  end
  # overriding so that label is redrawn, since this is the main property that is used.
  ## 2018-05-21 - we are now using attr_property so not required
  #def text=(_text)
    #@text = _text
    #self.touch
  #end
  # ADD HERE LABEL
end # }}}
end # module
