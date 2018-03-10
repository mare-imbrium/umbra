##
# Basic widget class superclass. Anything embedded in a form should
# extend this, if it wants to be repainted or wants focus. Otherwise.
# form will be unaware of it.
# 2018-03-08 - 
require './form.rb'
class Widget   
=begin
    require 'canis/core/include/action'          # added 2012-01-3 for add_action
    include EventHandler
    include Canis::Utils
    include Io # added 2010-03-06 13:05 
=end
  #include ConfigSetup
  # common interface for text related to a field, label, textview, button etc
  attr_accessor :text, :width, :height

  # foreground and background colors when focussed. Currently used with buttons and field
  # Form checks and repaints on entry if these are set.
  #attr_accessor :highlight_color, :highlight_bgcolor  # FIXME use color_pair
  attr_accessor :highlight_color_pair

  # NOTE: 2018-03-04 - user will have to call repaint or somthing like that if he changes color or coordinates.
  # FIXME 2018-03-04 - if there is a color and colorpair then just use the final one, ditch other.
  attr_accessor  :row, :col            # location of object
  #attr_writer :color, :bgcolor      # normal foreground and background 2018-03-08 - now color_pair
  # moved to a method which calculates color 2011-11-12 
  attr_accessor  :color_pair           # instead of colors give just color_pair
  attr_accessor  :attr                 # attribute bold, normal, reverse
  attr_accessor  :name                 # name to refr to or recall object by_name
  attr_accessor :id #, :zorder
  attr_accessor :curpos              # cursor position inside object - column, not row.
  attr_reader  :config             # can be used for popping user objects too
  attr_accessor  :form              # made accessor 2008-11-27 22:32 so menu can set
  attr_accessor :state              # normal, selected, highlighted
  attr_reader  :row_offset, :col_offset # where should the cursor be placed to start with
  attr_accessor  :visible # boolean     # 2008-12-09 11:29 
  # 2018-03-04 - we should use modified as accessor unless it is due to setting forms modified
  #attr_accessor :modified          # boolean, value modified or not (moved from field 2009-01-18 00:14 )
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

  def initialize aconfig={}, &block
    @row_offset ||= 0
    @col_offset ||= 0
    #@ext_row_offset = @ext_col_offset = 0 # 2010-02-07 20:18  # removed on 2011-09-29 
    @state = :NORMAL

    @handler = nil # we can avoid firing if nil
    #@event_args = {} # 2014-04-22 - 18:47 declared in bind_key
    # These are standard events for most widgets which will be fired by 
    # Form. In the case of CHANGED, form fires if it's editable property is set, so
    # it does not apply to all widgets.
    #register_events( [:ENTER, :LEAVE, :CHANGED, :PROPERTY_CHANGE])

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
  def set_modified tf=true
    @modified = tf
    @form.modified = true if tf
  end
  alias :modified :set_modified

  ## got left out by mistake 2008-11-26 20:20 
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
    # next line should be in same color but only have @att so we can change att is nec
    #@form.window.mvchgat(y=r, x=c, max=len, Ncurses::A_NORMAL, @bgcolor, nil)
  end

  def destroy
    $log.debug "DESTROY : widget #{@name} "
    panel = @window.panel
    Ncurses::Panel.del_panel(panel.pointer) if !panel.nil?   
    @window.delwin if !@window.nil?
  end

  # puts cursor on correct row.
  def set_form_row
    #  @form.row = @row + 1 + @winrow
    #@form.row = @row + 1 
    r, c = rowcol
    #$log.warn " empty set_form_row in widget #{self} r = #{r} , c = #{c}  "
    #raise "trying to set 0, maybe called repaint before container has set value" if row <= 0
    setrowcol row, nil
  end
  # set cursor on correct column, widget
  # Ideally, this should be overriden, as it is not likely to be correct.
  # NOTE: this is okay for some widgets but NOT for containers
  # that will call their own components SFR and SFC
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
  def remove
    raise "is remove called ? from where? why not call on the form"
    @form.remove_widget(self)
  end
  # is this required can we remove
  def move row, col
    raise "is move called ? from where? why "
    @row = row
    @col = col
  end
  ##
  # moves focus to this field
  # we must look into running on_leave of previous field
  def focus
    return if !@focusable
    if @form.validate_field != -1
      @form.select_field @id
    end
  end
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

  # is this widget accessible from keyboard or not.
  # 2018-03-04 - NOT_SURE why not attr_accessor  
  def focusable?
    @focusable
  end

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
  def repaint_required(tf=true)
    @repaint_required = tf
  end
  def repaint_all(tf=true)
    @repaint_all = tf
    @repaint_required = tf
  end

  ## 
  # When an enclosing component creates a pad (buffer) and the child component
  #+ should write onto the same pad, then the enclosing component should override
  #+ the default graphic of child. This applies mainly to editor components in
  #+ listboxes and tables. 
  # @param graphic graphic object to use for writing contents
  # @see prepare_editor in rlistbox.
  # added 2010-01-05 15:25 
  #
  #2018-03-04 - NOT_SURE
  def override_graphic gr
    @graphic = gr
  end

  ## passing a cursor up and adding col and row offsets
  ## Added 2010-01-13 13:27 I am checking this out.
  ## I would rather pass the value down and store it than do this recursive call
  ##+ for each cursor display
  # @see Form#setrowcol
  def setformrowcol r, c
    @form.row = r unless r.nil?
    @form.col = c unless c.nil?
    # this is stupid, going through this route i was losing windows top and left
    # And this could get repeated if there are mult objects. 
    if !@parent_component.nil? and @parent_component != self
      r+= @parent_component.form.window.top unless  r.nil?
      c+= @parent_component.form.window.left unless c.nil?
      $log.debug " (#{@name}) calling parents setformrowcol #{r}, #{c} pa: #{@parent_component.name} self: #{name}, #{self.class}, poff #{@parent_component.row_offset}, #{@parent_component.col_offset}, top:#{@form.window.left} left:#{@form.window.left} "
      @parent_component.setformrowcol r, c
    else
      # no more parents, now set form
      $log.debug " name NO MORE parents setting #{r}, #{c}    in #{@form} "
      @form.setrowcol r, c
    end
  end
  ## widget: i am putting one extra level of indirection so i can switch here
  # between form#setrowcol and setformrowcol, since i am not convinced either
  # are giving the accurate result. i am not sure what the issue is.
  def setrowcol r, c
    # 2010-02-07 21:32 is this where i should add ext_offsets
    #$log.debug " #{@name}  w.setrowcol #{r} + #{@ext_row_offset}, #{c} + #{@ext_col_offset}  "
    # commented off 2010-02-15 18:22 
    #r += @ext_row_offset unless r.nil?
    #c += @ext_col_offset unless c.nil?
    if @form
      @form.setrowcol r, c
      #elsif @parent_component
    else
      raise "Parent component not defined for #{self}, #{self.class} " unless @parent_component
      @parent_component.setrowcol r, c
    end
    #setformrowcol r,c 
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
