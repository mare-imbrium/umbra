##
# Basic widget class superclass. Anything embedded in a form should
# extend this, if it wants to be repainted or wants focus. Otherwise.
# form will be unaware of it.
# 2018-03-08 - 
require './form.rb'

class FieldValidationException < RuntimeError
end
class Widget   
    include EventHandler
  # common interface for text related to a field, label, textview, button etc
  attr_accessor :text, :width, :height

  # foreground and background colors when focussed. Currently used with buttons and field
  # Form checks and repaints on entry if these are set.
  attr_accessor :highlight_color_pair
  attr_accessor :highlight_attr

  # NOTE: 2018-03-04 - user will have to call repaint or somthing like that if he changes color or coordinates.
  attr_accessor  :row, :col            # location of object
  #attr_writer :color, :bgcolor      # normal foreground and background 2018-03-08 - now color_pair
  # moved to a method which calculates color 2011-11-12 
  attr_accessor  :color_pair           # instead of colors give just color_pair
  attr_accessor  :attr                 # attribute bold, normal, reverse
  attr_accessor  :name                 # name to refr to or recall object by_name
  #attr_accessor :id #, :zorder   UNUSED REMOVE
  attr_accessor :curpos              # cursor position inside object - column, not row.
  attr_reader  :config             # can be used for popping user objects too
  #attr_accessor  :form              # made accessor 2008-11-27 22:32 so menu can set
  attr_accessor  :graphic          # window which should be set by form when adding 2018-03-19
  attr_accessor :state              # normal, selected, highlighted
  attr_reader  :row_offset, :col_offset # where should the cursor be placed to start with
  attr_accessor  :visible          # boolean     # 2008-12-09 11:29 
  # if changing focusable property of a field after form creation, you may need to call
  # pack again, or atl east update_focusables
  attr_accessor  :focusable        # boolean     can this get focus # 2018-03-21 - 23:13 
  # 2018-03-04 - we should use modified as accessor unless it is due to setting forms modified
  # 2018-03-22 - making it accessor
  attr_accessor :modified          # boolean, value modified or not (moved from field 2009-01-18 00:14 )
  attr_accessor  :help_text          # added 2009-01-22 17:41 can be used for status/tooltips

  #attr_accessor :parent_component  # added 2010-01-12 23:28 BUFFERED - to bubble up

  # sometimes inside a container there's no way of knowing if an individual comp is in focus
  # other than to explicitly set it and inquire . 2010-09-02 14:47 @since 1.1.5
  # NOTE state takes care of this and is set by form. boolean
  attr_accessor :focussed  # is this widget in focus, so they may paint differently

  # height percent and width percent used in stacks and flows.
  attr_accessor :height_pc, :width_pc # tryin out in stacks and flows 2011-11-23 

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
    # $log.debug "widgte rowcol : #{@row+@row_offset}, #{@col+@col_offset}"
    return @row+@row_offset, @col+@col_offset
  end
  ## return the value of the widget.
  #  In cases where selection is possible, should return selected value/s
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
  def hide
    raise "is hide called ? from where? why not just visible"
    @visible = false
  end
  def show
    raise "is show called ? from where? why not just visible"
    @visible = true
  end
  # is this required can we remove
  def move row, col
    raise "is move called ? from where? why "
    @row = row
    @col = col
  end
=begin
  ##
  # moves focus to this field
  # we must look into running on_leave of previous field
  def focus
    # 2018-03-21 - removing methods that call form
    raise "focus being called. deprecated since it calls form"
    return if !@focusable
    if @form.validate_field != -1
      @form.select_field @id
    end
  end
=end
  # 2018-03-21 - replaced this with attr_accessor
=begin
  # set or unset focusable (boolean). Whether a widget can get keyboard focus.
  # 
  # 2018-03-04 - NOT_SURE
  def focusable(*val)
    return @focusable if val.empty?
    oldv = @focusable
    @focusable = val[0]

    return self if oldv.nil? || @_object_created.nil?
    # once the form has been painted then any changes will trigger update of focusables.
    @form.update_focusables if @form
    # actually i should only set the forms focusable_modified flag rather than call this. FIXME
    self
  end
=end

  def bind_key keycode, *args, &blk
    #$log.debug " #{@name} bind_key received #{keycode} "
    @_key_map ||= {}
    #
    # added on 2011-12-4 so we can pass a description for a key and print it
    # The first argument may be a string, it will not be removed
    # so existing programs will remain as is.
    @key_label ||= {}
    if args[0].is_a?(String) || args[0].is_a?(Symbol)
      @key_label[keycode] = args[0] 
    else
      @key_label[keycode] = :unknown
    end

    if !block_given?
      blk = args.pop
      raise "If block not passed, last arg should be a method symbol" if !blk.is_a? Symbol
      #$log.debug " #{@name} bind_key received a symbol #{blk} "
    end
    case keycode
    when String
      # single assignment
      keycode = keycode.getbyte(0) 
    when Array
      # 2018-03-10 - unused now delete
      # double assignment
      # this means that all these keys have to be pressed in succession for this block, like "gg" or "C-x C-c"
      raise "A one key array will not work. Pass without array" if keycode.size == 1
      ee = []
      keycode.each do |e| 
        e = e.getbyte(0) if e.is_a? String
        ee << e
      end
      #bind_composite_mapping ee, args, blk 2018-03-04 - commented
      return self
      #@_key_map[a0] ||= OrderedHash.new
      #@_key_map[a0][a1] = blk
      #$log.debug " XX assigning #{keycode} to  _key_map " if $log.debug? 
    else
      $log.debug " assigning #{keycode} to  _key_map for #{self.class}, #{@name}" if $log.debug? 
    end
    @_key_map[keycode] = blk
    @_key_args ||= {}
    @_key_args[keycode] = args
    self
  end

  def bind_keys keycodes, *args, &blk
    keycodes.each { |k| bind_key k, *args, &blk }
  end
  ##
  # remove a binding that you don't want
  def unbind_key keycode
    @_key_args.delete keycode unless @_key_args.nil?
    @_key_map.delete keycode unless @_key_map.nil?
  end

  # e.g. process_key ch, self
  # returns UNHANDLED if no block for it
  # after form handles basic keys, it gives unhandled key to current field, if current field returns
  # unhandled, then it checks this map.
  def process_key keycode, object
    return _process_key keycode, object, @graphic
  end
  ## 
  # to be added at end of handle_key of widgets so instlalled actions can be checked
  def handle_key(ch)
    ret = process_key ch, self
    return :UNHANDLED if ret == :UNHANDLED
    0
  end



  # to give simple access to other components, (eg, parent) to tell a comp to either
  # paint its data, or to paint all - borders, headers, footers due to a big change (ht/width)
  # earlier this was defaulting to true, but I am not using it as a question, not realizing that it is setting 
  #the value as true !
  #def repaint_required(tf)
    #@repaint_required = tf
  #end
  # is the entire widget to be repainted including things like borders and titles
  # earlier took a default of true, now must be explicit
  def repaint_all(tf)
    @repaint_all = tf
    @repaint_required = tf
  end


  # a general method for all widgets to override with their favorite or most meaninful event
  # Ideally this is where the block in the constructor should land up.
  # @since 1.5.0    2011-11-21 
  # 2018-03-08 - NOT_SURE 
  def command *args, &block
    if event? :PRESS
      bind :PRESS, *args, &block
    else
      bind :CHANGED, *args, &block
    end
  end
  #
  ## ADD HERE WIDGET
  # these is duplicated in form and widget. put in module Utils and include in both
  def _process_key keycode, object, window
    return :UNHANDLED if @_key_map.nil?
    blk = @_key_map[keycode]
    $log.debug "XXX:  _process key keycode #{keycode} #{blk.class}, #{self.class} "
    return :UNHANDLED if blk.nil?

    if blk.is_a? Symbol
      if respond_to? blk
        return send(blk, *@_key_args[keycode])
      else
        ## 2013-03-05 - 19:50 why the hell is there an alert here, nowhere else
        alert "This ( #{self.class} ) does not respond to #{blk.to_s} [PROCESS-KEY]"
        # added 2013-03-05 - 19:50 so called can know
        return :UNHANDLED 
      end
    else
      $log.debug "rwidget BLOCK called _process_key " if $log.debug? 
      return blk.call object,  *@_key_args[keycode]
    end
  end
end #  }}}
