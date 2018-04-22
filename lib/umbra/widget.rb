##
# Basic widget class superclass. Anything embedded in a form should
# extend this, if it wants to be repainted or wants focus. Otherwise.
# form will be unaware of it.
# 2018-03-08 - 
#require 'umbra/form'    # for EventHandler !!!
require 'umbra/eventhandler'         # for register_events and fire_handler etc
require 'umbra/keymappinghandler'    # for bind_key and process_key

module Umbra
class FieldValidationException < RuntimeError
end
class Widget   
    include EventHandler
    include KeyMappingHandler
  # common interface for text related to a field, label, textview, button etc
  attr_accessor :text, :width, :height

  # foreground and background colors when focussed. Currently used with buttons and field
  # Form checks and repaints on entry if these are set.
  attr_accessor :highlight_color_pair
  attr_accessor :highlight_attr

  # NOTE: 2018-03-04 - user will have to call repaint_required if he changes color or coordinates.
  attr_accessor  :row, :col                   # location of object
  #attr_writer :color, :bgcolor               # normal foreground and background 2018-03-08 - now color_pair
  # moved to a method which calculates color 2011-11-12 
  attr_accessor  :color_pair                  # instead of colors give just color_pair
  attr_accessor  :attr                        # attribute bold, normal, reverse
  attr_accessor  :name                        # name to refr to or recall object by_name
  attr_accessor :curpos                       # cursor position inside object - column, not row.
  attr_reader  :config                        # can be used for popping user objects too
  #attr_accessor  :form                       # made accessor 2008-11-27 22:32 so menu can set
  attr_accessor  :graphic                     # window which should be set by form when adding 2018-03-19
  attr_accessor :state                        # normal, selected, highlighted
  attr_reader  :row_offset, :col_offset       # where should the cursor be placed to start with
  attr_accessor  :visible                     # boolean     # 2008-12-09 11:29 
  # if changing focusable property of a field after form creation, you may need to call
  # pack again, or atl east update_focusables
  attr_reader   :focusable                   # boolean     can this get focus # 2018-03-21 - 23:13 
  # 2018-03-04 - we should use modified as accessor unless it is due to setting forms modified
  # 2018-03-22 - making it accessor
  attr_accessor :modified                     # boolean, value modified or not (moved from field 2009-01-18 00:14 )
  #attr_accessor  :help_text                   # added 2009-01-22 17:41 can be used for status/tooltips

  #attr_accessor :parent_component  # added 2010-01-12 23:28 BUFFERED - to bubble up

  # NOTE state takes care of this and is set by form. boolean
  attr_reader :focussed                    # is this widget in focus, so they may paint differently

  # height percent and width percent used in stacks and flows.
  #attr_accessor :height_pc, :width_pc        # may bring this back

  # descriptions for each key set in _key_map
  # 2018-03-07 - NOT_SURE
  attr_reader :key_label
  attr_reader :handler                       # event handler
  # adding as attr_accessor  2018-03-22 - 
  # is a repaint required or not, boolean
  attr_accessor  :repaint_required

  def initialize aconfig={}, &block
    @row_offset ||= 0
    @col_offset ||= 0
    @state = :NORMAL

    @handler = nil # we can avoid firing if nil
    # These are standard events for most widgets which will be fired by 
    # Form. In the case of CHANGED, form fires if it's editable property is set, so
    # it does not apply to all widgets.
    # 2018-03-18 - proporty change is deprecated since we don't use dsl_property any longer
    register_events( [:ENTER, :LEAVE, :CHANGED, :PROPERTY_CHANGE])
    @repaint_required = true # added 2018-03-20 - so all widgets get it

    aconfig.each_pair { |k,v| variable_set(k,v) }
    #instance_eval &block if block_given?
    if block_given?
      if block.arity > 0
        yield self
      else
        self.instance_eval(&block)
      end
    end
  end

  def variable_set var, val
    send("#{var}=", val) 
  end
  def init_vars
    # just in case anyone does a super. Not putting anything here
    # since i don't want anyone accidentally overriding
  end

  # modified
  ##
  # typically read will be overridden to check if value changed from what it was on enter.
  # getter and setter for modified (added 2009-01-18 12:31 )
  def modified?
    @modified
  end
  #def set_modified tf=true
    #@modified = tf
  #end
  #alias :modified :set_modified

  # triggered whenever a widget is entered.
  # TODO should we not fix cursor at this point ?
  def on_enter
    @state = :HIGHLIGHTED    # duplicating since often these are inside containers
    @focussed = true
    if @handler && @handler.has_key?(:ENTER)
      fire_handler :ENTER, self
    end
  end
  ## Called when user exits a widget
  # 2018-03-04 - Are we keeping this at all, can we avoid NOT_SURE
  def on_leave
    @state = :NORMAL    # duplicating since often these are inside containers
    @focussed = false
    if @handler && @handler.has_key?(:LEAVE)
      fire_handler :LEAVE, self
    end
  end
  ## 
  # @return row and col of a widget where painting data actually starts
  # row and col is where a widget starts. offsets usually take into account borders.
  # the offsets typically are where the cursor should be positioned inside, upon on_enter.
  def rowcol
    return @row+@row_offset, @col+@col_offset
  end
  ## return the value of the widget.
  def getvalue
    @text
  end
  ##
  # Am making a separate method since often value for print differs from actual value
  def getvalue_for_paint
    getvalue
  end
  ##
  # default repaint method. Called by form for all widgets.
  #  widget does not have display_length.
  def repaint
    r,c = rowcol
    $log.debug("widget repaint : r:#{r} c:#{c} col:#{@color_pair}" )
    value = getvalue_for_paint
    len = @width || value.length
    acolor = @color_pair 
    @graphic.printstring r, c, "%-*s" % [len, value], acolor, attr()
  end

  def destroy
    $log.debug "DESTROY : widget #{@name} "
    panel = @window.panel
    Ncurses::Panel.del_panel(panel.pointer) if !panel.nil?   
    @window.delwin if !@window.nil?
  end

  # puts cursor on correct row.
  def set_form_row
    raise "uncalled set_form_row"
    r, c = rowcol
    setrowcol row, nil  # does not exist any longer
  end
  # set cursor on correct column, widget
  # Ideally, this should be overriden, as it is not likely to be correct.
  # NOTE: this is okay for some widgets but NOT for containers
  # that will call their own components SFR and SFC
  #Currently, Field has overriden this. +setrowcol+ does not exist any longer.
  def set_form_col col1=@curpos
    @curpos = col1 || 0 # 2010-01-14 21:02 
    #@form.col = @col + @col_offset + @curpos
    c = @col + @col_offset + @curpos
    #$log.warn " #{@name} empty set_form_col #{c}, curpos #{@curpos}  , #{@col} + #{@col_offset} #{@form} "
    setrowcol nil, c
  end

  ## 
  # to be added at end of handle_key of widgets so instlalled actions can be checked
  def handle_key(ch)
    ret = process_key ch, self
    return :UNHANDLED if ret == :UNHANDLED
    0
  end

  # is the entire widget to be repainted including things like borders and titles
  # earlier took a default of true, now must be explicit. Perhaps, not used currently.
  def repaint_all(tf)
    @repaint_all = tf
    @repaint_required = tf
  end
  # shortcut for users to indicate that a widget should be redrawn since some property has been changed.
  def touch
    @repaint_required = true
  end


  # a general method for all widgets to override with their favorite or most meaninful event
  # Ideally this is where the block in the constructor should land up.
  # @since 1.5.0    2011-11-21 
  # 2018-03-08 - NOT_SURE 
  def command *args, &block
    if event? :PRESS
      bind_event :PRESS, *args, &block
    else
      bind_event :CHANGED, *args, &block
    end
  end
  def _form=(aform)
    @_form = aform
  end
  def focusable=(bool)
    $log.debug "  inside focusable= with #{bool} "
    @focusable = bool
    @_form.update_focusables if @_form
  end
  #
  ## ADD HERE WIDGET
end #  
end # module
