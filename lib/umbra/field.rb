# ----------------------------------------------------------------------------- #
#         File: field.rb
#  Description: text input field or widget
#       Author: j kepler  http://github.com/mare-imbrium/
#         Date: 2018-03
#      License: MIT
#  Last update: 2018-06-02 10:26
# ----------------------------------------------------------------------------- #
#  field.rb  Copyright (C) 2012-2018 j kepler
#

module Umbra
class InputDataEvent # {{{
  attr_accessor :index0, :index1, :source, :type, :row, :text
  def initialize index0, index1, source, type, row, text
    @index0 = index0
    @index1 = index1
    @source = source
    @type = type
    @row = row
    @text = text
  end
  # until now to_s was returning inspect, but to make it easy for users let us return the value
  # they most expect which is the text that was changed
  def to_s
    inspect
  end
  def inspect
    ## now that textarea.to_s prints content we shouldn pass it here.
    #"#{@type.to_s}, #{@source}, ind0:#{@index0}, ind1:#{@index1}, row:#{@row}, text:#{@text}"
    "#{@type.to_s}, ind0:#{@index0}, ind1:#{@index1}, row:#{@row}, text:#{@text}"
  end
  # this is so that earlier applications were getting source in the block, not an event. they 
  # were doing a fld.getvalue, so we must keep those apps running
  # @since 1.2.0  added 2010-09-11 12:25 
  def getvalue
    @source.getvalue
  end
end # class }}}
end # module  
  # Text edit field
#  Todo :
  # NOTE: +width+ is the length of the display whereas +maxlen+ is the maximum size that the value 
  # can take. Thus, +maxlen+ can exceed +width+. Currently, +maxlen+ defaults to +width+ which 
  # defaults to 20.
  # NOTE: Use +text=(val)+ to set value of field, and +text()+ to retrieve value.
  # == Example
  #     f = Field.new  text: "Some value", row: 10, col: 2
  #
# Field introduces an event :CHANGE which is fired for each character deleted or inserted.
##
# ## Use the :CHANGED event handler for custom validations and throw a +FieldValidationException+ if 
# ##  the validation fails. This is called in the +on_leave+. You may pass a block to the +command+ method
## for the same functionality.
  #  
  module Umbra
  class Field < Widget 
    attr_accessor :maxlen             # maximum length allowed into field
    attr_reader :buffer              # actual buffer being used for storage
    
  
    attr_accessor :values             # validate against provided list, (+include?+)
    attr_accessor :valid_regex        # validate against regular expression (+match()+)
    attr_accessor :valid_range        # validate against numeric range, should respond to +include?+
    # for numeric fields, specify lower or upper limit of entered value
    attr_accessor :below, :above

    # aliased to type
    #attr_accessor :chars_allowed           # regex, what characters to allow entry, will ignore all else
    # character to show, earlier called +show+ which clashed with Widget method +show+
    attr_accessor :mask                    # what charactr to show for each char entered (password field)
    attr_accessor :null_allowed            # allow nulls, don't validate if null # added , boolean

    # any new widget that has +editable+ should have +modified+ also
    attr_accessor :editable          # allow editing

    # +type+ is just a convenience over +chars_allowed+ and sets some basic filters 
    # @example:  :integer, :float, :alpha, :alnum
    # NOTE: we do not store type, only chars_allowed, so this won't return any value
    #attr_reader :type                          # datatype of field, currently only sets chars_allowed

    # this accesses the field created or passed with set_label
    #attr_reader :label
    # this is the class of the field set in +text()+, so value is returned in same class
    # @example : Integer, Integer, Float
    attr_accessor :datatype                    # currently set during set_buffer
    attr_reader :original_value                # value on entering field
    attr_accessor :overwrite_mode              # true or false INSERT OVERWRITE MODE

    # column on which field printed, usually the same as +col+ unless +label+ used.
    # Required by +History+ to popup field history. UNUSED.
    attr_reader :field_col                     # column on which field is printed
                                               # required due to labels. Is updated after printing
    #                                          # so can be nil if accessed early 

    def initialize config={}, &block
      @buffer = String.new
      @row = 0
      @col = 0
      @editable = true
      @focusable = true
    
      map_keys 
      init_vars
      register_events(:CHANGE)
      super
      @width ||= 20
      @maxlen ||= @width
    end
    def init_vars
      @pcol = 0                    # needed for horiz scrolling
      @curpos = 0                  # current cursor position in buffer (NOT screen/window/field)
                                   # this is the index where characters are put or deleted
      #                            # when user edits
      @modified = false
    end

    # NOTE: earlier there was some confusion over type, chars_allowed and datatype
    # Now type and chars_allowed are merged into one.
    # If you pass a symbol such as :integer, :float or Float Integer then some
    #  standard chars_allowed will be used. Otherwise you may pass a regexp.
    #
    # @param [symbol] :integer, :float, :alpha, :alnum, Float, Integer, Numeric, Regexp
    def type=(val)

      dtype = val
      #return self if @chars_allowed # disallow changing
      # send in a regexp, we just save it.
      if dtype.is_a? Regexp 
        @chars_allowed = dtype
        return self
      end
      dtype = dtype.to_s.downcase.to_sym if dtype.is_a? String
      case dtype # missing to_sym would have always failed due to to_s 2011-09-30 1.3.1
      when :integer, Integer
        @chars_allowed = /\d/
      when :numeric, :float, Numeric, Float
        @chars_allowed = /[\d\.]/ 
      when :alpha
        @chars_allowed = /[a-zA-Z]/ 
      when :alnum
        @chars_allowed = /[a-zA-Z0-9]/ 
      else
        raise ArgumentError, "Field type: invalid datatype specified. Use :integer, :numeric, :float, :alpha, :alnum "
      end
      self
    end
    alias :chars_allowed= :type=

    #
    # add a char to field, and validate
    # if disabled or exceeding size
    # @param [char] a character to add
    # @return [Integer] 0 if okay, -1 if not editable or exceeding length
    def putch char
      return -1 if !@editable 
      return -1 if !@overwrite_mode && (@buffer.length >= @maxlen)
      blen = @buffer.length
      if @chars_allowed != nil
        return if char.match(@chars_allowed).nil?
      end
      # added insert or overwrite mode 2010-03-17 20:11 
      oldchar = nil
      if @overwrite_mode
        oldchar = @buffer[@curpos] 
        @buffer[@curpos] = char
      else
        @buffer.insert(@curpos, char)
      end
      oldcurpos = @curpos
      #$log.warn "XXX:  FIELD CURPOS #{@curpos} blen #{@buffer.length} " #if @curpos > blen
      @curpos += 1 if @curpos < @maxlen
      @modified = true
      #$log.debug " FIELD FIRING CHANGE: #{char} at new #{@curpos}: bl:#{@buffer.length} buff:[#{@buffer}]"
      if @overwrite_mode
        fire_handler :CHANGE, InputDataEvent.new(oldcurpos,@curpos, self, :DELETE, 0, oldchar) # 2010-09-11 12:43 
      end
      fire_handler :CHANGE, InputDataEvent.new(oldcurpos,@curpos, self, :INSERT, 0, char) # 2010-09-11 12:43 
      0
    end

    ##
    # add character to field, adjust scrolling.
    # NOTE: handlekey only calls this if between 32 and 126.
    def putc c
      if c >= 0 and c <= 127
        ret = putch c.chr
        if ret == 0
          # character is valid
          if addcol(1) == -1  # if can't go forward, try scrolling
            # scroll if exceeding display len but less than max len
            if @curpos > @width && @curpos <= @maxlen
              @pcol += 1 if @pcol < @width 
            end
          end
          @modified = true
          return 0 
        end
      end
      return -1
    end
    # delete a character from the buffer at given position
    # Called by +delete_curr_char+ and +delete_prev_char+.
    def delete_at index=@curpos
      return -1 if !@editable 
      char = @buffer.slice!(index,1)
      #$log.debug " delete at #{index}: #{@buffer.length}: #{@buffer}"
      @modified = true
      fire_handler :CHANGE, InputDataEvent.new(@curpos,@curpos, self, :DELETE, 0, char)     # 2010-09-11 13:01 
    end
    #
    # silently restores earlier value without firing handlers, use if exception and you want old value
    # Called when pressing <ESC> or <c-g>.
    def restore_original_value
      $log.debug "  FIELD: buffer:#{@buffer}. orig:#{@original_value}: "
      $log.debug "  original value is null " unless @original_value
      $log.debug "  buffer value is null " unless @buffer
      @buffer = @original_value.dup
      # earlier commented but trying again, since i am getting IndexError in insert 2188
      # Added next 3 lines to fix issue, now it comes back to beginning.
      cursor_home

      @repaint_required = true
    end
    ## 
    # set value of Field
    # fires CHANGE handler
    # Please don't use this directly, use +text+
    # This name is from ncurses field, added underscore to emphasize not to use
    private def _set_buffer value   #:nodoc:
      @repaint_required = true
      @datatype = value.class
      @delete_buffer = @buffer.dup
      @buffer = value.to_s.dup
      # don't allow setting of value greater than maxlen
      @buffer = @buffer[0,@maxlen] if @maxlen && @buffer.length > @maxlen
      @curpos = 0
      # hope @delete_buffer is not overwritten
      fire_handler :CHANGE, InputDataEvent.new(@curpos,@curpos, self, :DELETE, 0, @delete_buffer)     # 2010-09-11 13:01 
      fire_handler :CHANGE, InputDataEvent.new(@curpos,@curpos, self, :INSERT, 0, @buffer)     # 2010-09-11 13:01 
      self # 2011-10-2 
    end
    ## add a column to cursor position. Field
    private def addcol num
      x = @col_offset + num
      return -1 if x < 0
      return -1 if x > @width
      @col_offset += num 
    end

    # converts back into original type
    #  changed to convert on 2009-01-06 23:39 
    #  2018-04-13 - Changed from private to public since I got an error on on_leave
    #    when this was called from LabeledField.
    def getvalue
      dt = @datatype || String
      case dt.to_s
      when "String"
        return @buffer
      when "Integer"
        return @buffer.to_i
      when "Float"
        return @buffer.to_f
      else
        return @buffer.to_s
      end
    end
  

    public

  def repaint
    return unless @repaint_required
    $log.debug("repaint FIELD: #{name}, r:#{row} c:#{col},wid:#{width},maxlen: #{@maxlen},pcol:#{@pcol},  #{focusable} st: #{@state} ")
    @width = 1 if width == 0
    printval = getvalue_for_paint().to_s
    printval = mask()*printval.length unless @mask.nil?
    if !printval.nil? 
      if printval.length > width # only show maxlen
        printval = printval[@pcol..@pcol+width-1] 
      else
        printval = printval[@pcol..-1]
      end
    end
  
    acolor = @color_pair || CP_WHITE
    if @state == :HIGHLIGHTED
      acolor = @highlight_color_pair || CP_RED
    end
    #$log.debug " Field g:#{@graphic}. r,c,displen:#{@row}, #{@col}, #{@width} c:#{@color} bg:#{@bgcolor} a:#{@attr} :#{@name} "
    r = row
    c = col
    @graphic.printstring r, c, sprintf("%-*s", width, printval), acolor, attr()
    @field_col = c
    @repaint_required = false
  end

  def map_keys
    return if @keys_mapped
    bind_key(FFI::NCurses::KEY_LEFT, :cursor_backward )
    bind_key(FFI::NCurses::KEY_RIGHT, :cursor_forward )
    bind_key(FFI::NCurses::KEY_BACKSPACE, :delete_prev_char )
    bind_key(127, :delete_prev_char )
    bind_key(330, :delete_curr_char )
    bind_key(?\C-a, :cursor_home )
    bind_key(?\C-e, :cursor_end )
    bind_key(?\C-k, :delete_eol )
    bind_key(?\C-_, :undo_delete_eol )
    #bind_key(27){ text @original_value }
    bind_key(?\C-g, 'revert'){ restore_original_value } 
    @keys_mapped = true
  end

  # field - handle a key sent for form
  # 
  def handle_key ch
    $log.debug "inside handle key of field with #{ch}"
    @repaint_required = true 
    case ch
    when 32..126
      putc ch
    when 27 # cannot bind it, so hardcoding it here
      restore_original_value
    else
      ret = super
      return ret
    end
    0 # 2008-12-16 23:05 without this -1 was going back so no repaint
  end
  # does an undo on delete_eol, not a real undo
  def undo_delete_eol
    return if @delete_buffer.nil?
    #oldvalue = @buffer
    @buffer.insert @curpos, @delete_buffer 
    fire_handler :CHANGE, InputDataEvent.new(@curpos,@curpos+@delete_buffer.length, self, :INSERT, 0, @delete_buffer)     
  end


  ## 
  # position cursor at start of field
  def cursor_home
    @curpos = 0
    @pcol = 0
    set_col_offset 0
  end
  ##
  # goto end of field, "end" is a keyword so could not use it.
  def cursor_end
    blen = @buffer.rstrip.length
    if blen < @width
      set_col_offset blen
    else
      @pcol = blen-@width
      #set_form_col @width-1
      set_col_offset blen
    end
    @curpos = blen # this is position in array where editing or motion is to happen regardless of what you see
                   # regardless of pcol (panning)
  end
  # sets the visual cursor on the window at correct place
  # NOTE be careful of curpos - pcol being less than 0
  private def set_col_offset x=@curpos
    @curpos = x || 0 # NOTE we set the index of cursor here
    #return -1 if x < 0
    #return -1 if x > @width
    if x > @width
      x = @width
    end
    @col_offset = x
    return
=begin
    c = @col + @col_offset + @curpos - @pcol
    min = @col + @col_offset
    max = min + @width
    c = min if c < min
    c = max if c > max
    #$log.debug " #{@name} FIELD set_form_col #{c}, curpos #{@curpos}  , #{@col} + #{@col_offset} pcol:#{@pcol} "
    #setrowcol nil, c  # this does not exist since it called form
=end
  end
  def delete_eol
    return -1 unless @editable
    pos = @curpos-1
    @delete_buffer = @buffer[@curpos..-1]
    # if pos is 0, pos-1 becomes -1, end of line!
    @buffer = pos == -1 ? "" : @buffer[0..pos]
    fire_handler :CHANGE, InputDataEvent.new(@curpos,@curpos+@delete_buffer.length, self, :DELETE, 0, @delete_buffer)
    return @delete_buffer
  end
  # move cursor forward one character, called with KEY_RIGHT action.
  def cursor_forward
    if @curpos < @buffer.length 
      if addcol(1)==-1  # go forward if you can, else scroll
        @pcol += 1 if @pcol < @width 
      end
      @curpos += 1
    end
   # $log.debug " crusor FORWARD cp:#{@curpos} pcol:#{@pcol} b.l:#{@buffer.length} d_l:#{@display_length} fc:#{@form.col}"
  end
  # move cursor back one character, called with KEY_LEFT action.
  def cursor_backward
    if @curpos > 0
      @curpos -= 1
      #if @pcol > 0 #and @form.col == @col + @col_offset
        #@pcol -= 1
      #end
      addcol -1
    elsif @pcol > 0 
      # pan left only when cursor pos is 0
      @pcol -= 1   
    end
 #   $log.debug " crusor back cp:#{@curpos} pcol:#{@pcol} b.l:#{@buffer.length} d_l:#{@display_length} fc:#{@form.col}"
=begin
# this is perfect if not scrolling, but now needs changes
    if @curpos > 0
      @curpos -= 1
      addcol -1
    end
=end
  end
    def delete_curr_char
      return -1 unless @editable
      delete_at
      @modified = true
    end
    # called when user presses backspace.
    # Delete character on left of cursor
    def delete_prev_char
      return -1 if !@editable 
      return if @curpos <= 0
      # if we've panned, then unpan, and don't move cursor back
      # Otherwise, adjust cursor (move cursor back as we delete)
      adjust = true
      if @pcol > 0
        @pcol -= 1
        adjust = false
      end
      @curpos -= 1 if @curpos > 0
      delete_at
      addcol -1 if adjust # move visual cursor back
      @modified = true
    end
    # Upon leaving a field
    # returns false if value not valid as per values or valid_regex
    # 2008-12-22 12:40 if null_allowed, don't validate, but do fire_handlers
    def on_leave
      val = getvalue
      #$log.debug " FIELD ON LEAVE:#{val}. #{@values.inspect}"
      valid = true
      if val.to_s.empty? && @null_allowed
        #$log.debug " empty and null allowed"
      else
        if !@values.nil?
          valid = @values.include? val
          raise FieldValidationException, "Field value (#{val}) not in values: #{@values.join(',')}" unless valid
        end
        if !@valid_regex.nil?
          valid = @valid_regex.match(val.to_s)
          raise FieldValidationException, "Field not matching regex #{@valid_regex}" unless valid
        end
        # added valid_range for numerics 2011-09-29 
        if !in_range?(val)
          raise FieldValidationException, "Field not matching range #{@valid_range}, above #{@above} or below #{@below}  "
        end
        
        ## 2018-05-24 - seems we were not calling the :CHANGED listeners at all.
        fire_handler :CHANGED, self

      end
      # here is where we should set the forms modified to true - 2009-01
      ## 2018-05-26 - what is the point of this ? 
      if modified?
        @modified = true
      end
      # if super fails we would have still set modified to true
      super
      #return valid
    end

    # checks field against +valid_range+, +above+ and +below+ , returning +true+ if it passes
    # set attributes, +false+ if it fails any one.
    def in_range?( val )
      val = val.to_i
      (@above.nil? or val > @above) and
        (@below.nil? or val < @below) and
        (@valid_range.nil? or @valid_range.include?(val))
    end
    ## save original value on enter, so we can check for modified.
    #  2009-01-18 12:25 
    #   2011-10-9 I have changed to take @buffer since getvalue returns a datatype
    #   and this causes a crash in set_original on cursor forward.
    def on_enter
      #@original_value = getvalue.dup rescue getvalue
      @original_value = @buffer.dup # getvalue.dup rescue getvalue
      $log.debug "  FIELD ORIGINAL VALUE is null in on_enter" unless @original_value
      $log.debug "  on_enter: setting original_value to #{@original_value}"
      super
    end
    ##
    # overriding widget, check for value change
    # 2018-05-26 - WHAT IS THE POINT of setting @modified if we have a different logic here
    def modified?
      getvalue() != @original_value
    end
    # 2018-03-22 - replaced the old style text(val) with attr style
    def text
      getvalue
    end

    ## set default value of field
    def text=(val)
      return unless val # added 2010-11-17 20:11, dup will fail on nil
      # will bomb on integer or float etc !!
      #_set_buffer(val.dup)
      _set_buffer(val)
    end
    alias :default= :text=
  # ADD HERE FIELD
  end # }}}
  end # module
