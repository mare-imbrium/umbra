##
# Basic widget class superclass. Anything embedded in a form should
# extend this, if it wants to be repainted or wants focus. Otherwise.
# form will be unaware of it.
# 2018-03-08 - 

require 'umbra/eventhandler'         # for register_events and fire_handler etc
require 'umbra/keymappinghandler'    # for bind_key and process_key

class Module # {{{

  # dsl method for declaring attribute setters which result in widget
  # being repainted. Also, fire a #fire_property_change event.
  # @param symbols [Symbol] value to be set
  # @return [Widget] self
  def attr_property(*symbols)
    symbols.each { |sym|
      class_eval %{
        def #{sym}=(val)
          oldvalue = @#{sym}
          newvalue = val
          if @_object_created.nil?
             @#{sym} = newvalue
          end
          # return(self) if oldvalue.nil? || @_object_created.nil?
          return(self) if @_object_created.nil?

          if oldvalue != newvalue
            begin
              fire_property_change("#{sym}", oldvalue, newvalue)
              @#{sym} = newvalue
            rescue PropertyVetoException
              $log.warn "PropertyVetoException for #{sym}:" + oldvalue.to_s + "->  "+ newvalue.to_s
            end
          end # oldvalue !=
          self
        end # def
    attr_reader sym
      }
    }
  end # def
end # module }}}
module Umbra

  ## Exception thrown by Field if validation fails
  class FieldValidationException < RuntimeError
  end


  ## Parent class of all widgets/controls that are displayed on the screen/window
  ## and are managed by +Form+.
  ## Many attributes use `attr_property` instead of `attr_accessor`. This is used for elements
  ## that must repaint the widget whenever updated. They also fire a property change event.
  ## These properties may not show up in the generated RDoc.
  ## This class will not be instantiated by programs, only its subclasses will be.
  class Widget   
    include EventHandler
    include KeyMappingHandler

    ## @param text [String] common interface for text related to a field, label, textview, button etc
    attr_property :text
    ## @param width [Integer] width of widget, same for +height+
    attr_property   :width, :height   ## width and height of widget

    # foreground and background colors when focussed. Currently used with buttons and field
    # Form checks and repaints on entry if these are set.
    ## @param highlight_color_pair [Integer] color pair of widget when focussed
    attr_property :highlight_color_pair
    ## @param highlight_attr [Integer] visual attribute of widget when focussed
    attr_property :highlight_attr

    attr_accessor  :col                   # location of object (column)
    attr_writer    :row                   # location of object

    ## @param color_pair [Integer] color pair of widget (when not focussed)
    attr_property  :color_pair                  # instead of colors give just color_pair
    ## @param attr [Integer] visual attribute of widget when not focussed
    attr_property  :attr                        # attribute bold, normal, reverse

    attr_accessor  :name                        # documentation, used in print statements
    attr_accessor :curpos                       # cursor position inside object - column, not row.


    attr_accessor  :graphic                     # window which should be set by form when adding 
    attr_accessor :state                        # :NORMAL, :SELECTED, :HIGHLIGHTED
    attr_reader  :row_offset, :col_offset       # where should the cursor be placed to start with

    ## @param attr [true, false] should the widget be displayed or not
    attr_property  :visible 

    attr_reader   :focusable                   # boolean     can this get focus or not.

  attr_accessor :modified                     # boolean, value modified or not

  #attr_accessor :parent_component  # added 2010-01-12 23:28 BUFFERED - to bubble up


  # @return [String] descriptions for each key set in _key_map, NOT YET displayed TODO
  attr_reader :key_label

  # @return [Hash]  event handler hash containing key and block association
  attr_reader :handler                       

  # @param repaint_required [true, false] is a repaint required or not, boolean
  attr_accessor  :repaint_required

  def initialize aconfig={}, &block
    @row_offset ||= 0
    @col_offset ||= 0
    @state = :NORMAL

    @handler = nil # we can avoid firing if nil
    # These are standard events for most widgets which will be fired by 
    # Form. In the case of CHANGED, form fires if it's editable property is set, so
    # it does not apply to all widgets.
    register_events( [:ENTER, :LEAVE, :CHANGED, :PROPERTY_CHANGE])
    @repaint_required = true

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

  def variable_set var, val #:nodoc:
    send("#{var}=", val) 
  end

  ## Initialise internal variables
  def init_vars  #:nodoc:
    # just in case anyone does a super. Not putting anything here
    # since i don't want anyone accidentally overriding
  end

  # widget modified or not.
  #
  # typically read will be overridden to check if value changed from what it was on enter.
  def modified?
    @modified
  end

  # triggered whenever a widget is entered.
  ## Will invoke `:ENTER` handler/event
  def on_enter
    ## Form has already set this, and set modified to false
    @state = :HIGHLIGHTED    # duplicating since often these are inside containers
    #@focussed = true
    if @handler && @handler.has_key?(:ENTER)
      fire_handler :ENTER, self
    end
  end

  ## Called when user exits a widget
  ## Will invoke `:LEAVE` handler/event
  def on_leave
    @state = :NORMAL    # duplicating since often these are inside containers
    #@focussed = false
    if @handler && @handler.has_key?(:LEAVE)
      fire_handler :LEAVE, self
    end
  end


  ## 
  # Returns row and col is where a widget starts. offsets usually take into account borders.
  # the offsets typically are where the cursor should be positioned inside, upon on_enter.
  # @return row and col of a widget where painting data actually starts
  def rowcol
    return self.row+@row_offset, self.col+@col_offset
  end

  ## @return [String] the value of the widget.
  def getvalue
    @text
  end

  ##
  # Am making a separate method since often value for print differs from actual value
  ## @return [String] the value of the widget for painting.
  def getvalue_for_paint
    getvalue
  end

  ##
  # Default repaint method. Called by form for all widgets.
  # widget does not have display_length. This should be overriden by concrete subclasses.
  def repaint
    r,c = rowcol
    $log.debug("widget repaint : r:#{r} c:#{c} col:#{@color_pair}" )
    value = getvalue_for_paint
    len = self.width || value.length
    acolor = @color_pair 
    @graphic.printstring r, c, "%-*s" % [len, value], acolor, attr()
  end


  def set_form_row #:nodoc:
    raise "uncalled set_form_row"
    r, c = rowcol
    setrowcol row, nil  # does not exist any longer
  end

  # set cursor on correct column, widget
  # Ideally, this should be overriden, as it is not likely to be correct.
  # NOTE: this is okay for some widgets but NOT for containers
  # that will call their own components SFR and SFC
  # Currently, Field has overriden this. +setrowcol+ does not exist any longer.
  def set_form_col col1=@curpos
    @curpos = col1 || 0 # 2010-01-14 21:02 
    #@form.col = @col + @col_offset + @curpos
    c = @col + @col_offset + @curpos
    #$log.warn " #{@name} empty set_form_col #{c}, curpos #{@curpos}  , #{@col} + #{@col_offset} #{@form} "
    setrowcol nil, c
  end

  # Handle keys entered by user when this widget is focussed. Executes blocks bound to given key or 
  # else returns control to +Form+.
  # To be called at end of `handle_key` of widgets so installed actions can be executed.
  # @param ch [Integer] keystroke entered
  # @return [0, :UNHANDLED] return value of block executed for given keystroke
  def handle_key(ch)
    ret = process_key ch, self
    return :UNHANDLED if ret == :UNHANDLED
    0
  end

  # is the entire widget to be repainted including things like borders and titles
  # earlier took a default of true, now must be explicit. Perhaps, not used currently.
  def repaint_all(tf)  #:nodoc:
    # NOTE NOT USED
    raise " not used repaint all"
    @repaint_all = tf
    @repaint_required = tf
  end

  # Shortcut for users to indicate that a widget should be redrawn since some property has been changed.
  # Now that I have created +attr_property+ this may not be needed
  def touch
    @repaint_required = true
  end


  ## A general method for all widgets to override with their favorite or most meaninful event
  ## This is a convenience method. Widgets that have a `PRESS` event will bind the given block to PRESS,
  ## all others to the `CHANGED` event.
  def command *args, &block
    if event? :PRESS
      bind_event :PRESS, *args, &block
    else
      bind_event :CHANGED, *args, &block
    end
  end

  def _form=(aform)    #:nodoc:
    @_form = aform
  end

  ## set focusable property to true or false
  ## Also updates the focusables array.
  def focusable=(bool)
    #$log.debug "  inside focusable= with #{bool} "
    @focusable = bool
    @_form.update_focusables if @_form
  end

  ## Get width of widget, treating negatives as relative width.
  ## @return [Integer, nil] returns width of widget 
  def width
    return nil unless @width    ## this is required otherwise checking for nil will fail
    if @width < 0
      return ( FFI::NCurses.COLS + @width ) - self.col + 1
    end
    @width
  end

  ## Get height of widget. Used only for +Multline+ widgets
  ## @return [Integer, nil] height of widget if applicable
  def height
    return nil unless @height
    if @height < 0
      return ((FFI::NCurses.LINES + @height) - self.row) + 1
      #return (FFI::NCurses.LINES + @height) 
    end
    @height
  end

  ## get row of widget
  ## @return [Integer, nil] row of widget 
  def row
    return nil unless @row
    if @row < 0
      return FFI::NCurses.LINES + @row
    end
    @row
  end
  
  end # class  
end # module
