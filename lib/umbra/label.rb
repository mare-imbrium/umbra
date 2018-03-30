# ----------------------------------------------------------------------------- #
#         File: label.rb
#  Description: an ncurses label
#               The preferred way of printing text on screen, esp if you want to modify it at run time.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-08 - 14:04
#      License: MIT
#  Last update: 2018-03-30 14:56
# ----------------------------------------------------------------------------- #
#  label.rb  Copyright (C) 2018-2020 j kepler
#
#require './widget.rb'
require 'umbra/widget'
class Label < Widget 

  # justify required a display length, esp if center.
  attr_accessor   :justify        #:right, :left, :center

  def initialize config={}, &block

    @text = config.fetch(:text, "NOTFOUND")
    @editable = false
    @focusable = false
    # we have some processing for when a form is attached, registering a hotkey
    #register_events :FORM_ATTACHED
    super
    @justify ||= :left
    @name ||= @text
    @repaint_required = true
  end
  #
  # get the value for the label
  def getvalue
    @text
  end
  # 2018-03-08 - NOT_SURE
  def label_for field
    @label_for = field
  end

  ## hotkey {{{
  # for a button, fire it when label invoked without changing focus
  # for other widgets, attempt to change focus to that field
  def bind_hotkey
    raise "calls to form"
    if @mnemonic
      ch = @mnemonic.downcase()[0].ord   ##  1.9 DONE 
      # meta key 
      mch = ?\M-a.getbyte(0) + (ch - ?a.getbyte(0))  ## 1.9
      if (@label_for.is_a? Canis::Button ) && (@label_for.respond_to? :fire)
        # FIXME call to form XXX
        @form.bind_key(mch, "hotkey for button #{@label_for.text} ") { |_form, _butt| @label_for.fire }
      else
        $log.debug " bind_hotkey label for: #{@label_for}"
        @form.bind_key(mch, "hotkey for label #{text} ") { |_form, _field| @label_for.focus }
      end
    end
  end # }}}

  ##
  # label's repaint - I am removing wrapping and Array stuff and making it simple 2011-11-12 
  def repaint
    return unless @repaint_required
    raise "Label row or col is nil #{@row} , #{@col}, #{@text} " if @row.nil? || @col.nil?
    r,c = rowcol
    $log.debug "label repaint #{r} #{c} #{@text} "

    # value often nil so putting blank, but usually some application error
    value = getvalue_for_paint || ""

    if value.is_a? Array
      value = value.join " "
    end
    # ensure we do not exceed
    if @width
      if value.length > @width
        value = value[0..@width-1]
      end
    end
    len = @width || value.length
    acolor = @color_pair  || 0
    str = @justify.to_sym == :right ? "%*s" : "%-*s"  # added 2008-12-22 19:05 

    #@graphic ||= @form.window
    # clear the area
    @graphic.printstring r, c, " " * len , acolor, @attr
    if @justify.to_sym == :center
      padding = (@width - value.length)/2
      value = " "*padding + value + " "*padding # so its cleared if we change it midway
    end
    @graphic.printstring r, c, str % [len, value], acolor, @attr
    if @mnemonic
      ulindex = value.index(@mnemonic) || value.index(@mnemonic.swapcase)
      @graphic.mvchgat(y=r, x=c+ulindex, max=1, Ncurses::A_BOLD|Ncurses::A_UNDERLINE, acolor, nil)
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
  # ADD HERE LABEL
end # }}}
