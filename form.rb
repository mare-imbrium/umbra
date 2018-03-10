##
# Manages the controls/widgets on a screen. 
# Manages traversal, rendering and events of all widgets that are associated with it
# via the +add_widget+ method.
#
# Passes keys pressed by user to the current field.
# Any keys that are not handled by the current field, are handled by the form if the application
# has bound the key via +bind_key+.    
# NOTE : 2018-03-08 - now using @focusables instead of @widgets in traversal.
#        active_index is now index into focusables.
class Form # {{{
  # array of widgets
  attr_reader :widgets

  # related window used for printing
  attr_accessor :window

  # cursor row and col
  attr_accessor :row, :col
  # color and bgcolor for all widget, widgets that don't have color specified will inherit from form
  # If not mentioned, then global defaults will be taken
  #attr_writer :color, :bgcolor
  # used at all NOT_SURE 
  attr_accessor :color_pair
  attr_accessor :attr

  # has the form been modified
  attr_accessor :modified

  # index of active widget inside focusables array
  attr_accessor :active_index

  # name given to form for debugging
  attr_accessor :name 

  def initialize win, &block
    @window = win
    ## added 2014-05-01 - 20:43 so that a window can update its form, during overlapping forms.
    #@window.form = self if win
    @widgets = []
    #@active_index = -1
    @active_index = nil                  # 2018-03-07 - if a form has no focusable field
    #@row = @col = -1
    @row = @col = 0                    # 2018-03-07 - umbra
    @modified = false
    @resize_required = true
    @focusables = []                   # focusable components
    #@focusable = true                # not used i think 2018-03-08 - 
    instance_eval &block if block_given?
    @name ||= ""

    # for storing error message NOT_SURE
    #$error_message ||= Variable.new ""

    map_keys unless @keys_mapped
  end
  ##
  # Add given widget to widget list and returns an incremental id.
  # Adding to widgets, results in it being painted, and focussed.
  # removing a widget and adding can give the same ID's, however at this point we are not 
  # really using ID. But need to use an incremental int in future. (internal use)
  # TODO allow passing several widgets
  def add_widget widget
    widget.form = self
    @widgets << widget
    return @widgets.length-1
  end
  #alias :add :add_widget

  # remove a widget
  # (internal use)
  def remove_widget widget
    @widgets.delete widget
  end
  # decide layout of objects. User has to call this after creating components
  def pack
    @focusables = @widgets.select { |w| w.focusable? }
    @active_index = 0 if @focusables.size > 0
    repaint
  end

  public

  # form repaint,calls repaint on each widget which will repaint it only if it has been modified since last call.
  # called after each keypress.
  def repaint
    $log.debug " form repaint:#{self}, #{@name} , r #{@row} c #{@col} " if $log.debug? 
    @widgets.each do |f|
      next if f.visible == false
      f.repaint
    end

    ###  this can bomb if someone sets row. We need a better way!
    #if @row == -1 and @_firsttime == true
    #select_first_field
    #@_firsttime = false
    #end
    setpos 
    @window.wrefresh
    # 2018-03-07 - commented next off NOT_SURE
    #Ncurses::Panel.update_panels ## added 2010-11-05 00:30 to see if clears the stdscr problems
  end
  ## 
  # move cursor to where the fields row and col are
  # private
  def setpos r=@row, c=@col
    #$log.debug "setpos : (#{self.name}) #{r} #{c} XXX"
    ## adding just in case things are going out of bounds of a parent and no cursor to be shown
    return if r.nil? or c.nil?  # added 2009-12-29 23:28 BUFFERED
    return if r<0 or c<0  # added 2010-01-02 18:49 stack too deep coming if goes above screen
    @window.wmove r,c
  end
  # @return [Widget, nil] current field, nil if no focusable field
  def get_current_field
    #select_next_field if @active_index == -1
    return nil if @active_index.nil?   # for forms that have no focusable field 2009-01-08 12:22 
    @focusables[@active_index]
  end
  alias :current_widget :get_current_field
  # take focus to first focussable field
  # we shoud not send to select_next. have a separate method to avoid bugs.
  # but check current_field, in case called from anotehr field TODO FIXME
  def select_first_field
    select_field 0
  end

  # take focus to last field on form
  # 2018-03-08 - WHY IS THIS REQUIRED NOT_SURE 
  def select_last_field
    raise
    return nil if @active_index.nil?   # for forms that have no focusable field 2009-01-08 12:22 
    i = @focusables.length -1
    select_field i
  end


  ## do not override
  # form's trigger, fired when any widget loses focus
  #  This wont get called in editor components in tables, since  they are formless 
  def on_leave f
    return if f.nil? || !f.focusable # added focusable, else label was firing
    f.state = :NORMAL
    # on leaving update text_variable if defined. Should happen on modified only
    # should this not be f.text_var ... f.buffer ?  2008-11-25 18:58 
    #f.text_variable.value = f.buffer if !f.text_variable.nil? # 2008-12-20 23:36 
    f.on_leave if f.respond_to? :on_leave
    # 2014-04-24 - 17:42 NO MORE ENTER LEAVE at FORM LEVEL
    #fire_handler :LEAVE, f 
    ## to test XXX in combo boxes the box may not be editable by be modified by selection.
    #if f.respond_to? :editable and f.modified?
    #$log.debug " Form about to fire CHANGED for #{f} "
    #f.fire_handler(:CHANGED, f) 
    #end
  end
  # form calls on_enter of each object.
  # However, if a multicomponent calls on_enter of a widget, this code will
  # not be triggered. The highlighted part
  # 2018-03-07 - NOT_SURE
  def on_enter f
    raise
    return if f.nil? || !f.focusable # added focusable, else label was firing 2010-09

    f.state = :HIGHLIGHTED
    # If the widget has a color defined for focussed, set repaint
    #  otherwise it will not be repainted unless user edits !
    if f.highlight_color_pair
      f.repaint_required true
    end

    f.modified false
    #f.set_modified false
    f.on_enter if f.respond_to? :on_enter
    # 2014-04-24 - 17:42 NO MORE ENTER LEAVE at FORM LEVEL
    #fire_handler :ENTER, f 
  end

  ##
  # puts focus on the given field/widget index
  # @param index of field in @widgets (or can be a Widget too)
  # XXX if called externally will not run a on_leave of previous field
  def select_field ix0
    if ix0.is_a? Widget
      ix0 = @focusables.index(ix0)
    end
    return if @focusables.nil? or @focusables.empty?
    #$log.debug "inside select_field :  #{ix0} ai #{@active_index}" 
    f = @focusables[ix0]
    return if !f.focusable?
    if f.focusable?
      @active_index = ix0
      @row, @col = f.rowcol
      #on_enter f
      @window.wmove @row, @col # added RK FFI 2011-09-7 = setpos

      #f.set_form_row # added 2011-10-5 so when embedded in another form it can get the cursor
      #f.set_form_col # this can wreak havoc in containers, unless overridden

      repaint
      @window.refresh
    else
      $log.debug "inside select field ENABLED FALSE :   act #{@active_index} ix0 #{ix0}" 
    end
  end
  ##
  # run validate_field on a field, usually whatevers current
  # before transferring control
  # We should try to automate this so developer does not have to remember to call it.
  # # @param field object
  # @return [0, -1] for success or failure
  # NOTE : catches exception and sets $error_message, check if -1
  def validate_field f=@focusables[@active_index]
    begin
      on_leave f
    rescue => err
      $log.error "form: validate_field caught EXCEPTION #{err}"
      $log.error(err.backtrace.join("\n")) 
      #        $error_message = "#{err}" # changed 2010  
      $error_message.value = "#{err}"
      Ncurses.beep
      return -1
    end
    return 0
  end
  # put focus on next field
  # will cycle by default, unless navigation policy not :CYCLICAL
  # in which case returns :NO_NEXT_FIELD.
  # FIXME: in the beginning it comes in as -1 and does an on_leave of last field
  # 2018-03-07 - UMBRA: let us force user to run validation when he does next field
  def select_next_field
    return :UNHANDLED if @focusables.nil? || @focusables.empty?
    #$log.debug "insdie sele nxt field :  #{@active_index} WL:#{@widgets.length}" 
    if @active_index.nil?  || @active_index == -1 # needs to be tested out A LOT
      # what is this silly hack for still here 2014-04-24 - 13:04  DELETE FIXME
      @active_index = -1 
      @active_index = 0     # 2018-03-08 - NOT_SURE
    end
    f = @focusables[@active_index]
    #index = @focusables.index(f)
    index = @active_index
    index = index ? index+1 : 0
    #f = @focusables[index]
    f = @focusables[index]
    if f
      select_field f 
      return 0
    end
    #
    $log.debug "inside sele nxt field : NO NEXT  #{@active_index} WL:#{@widgets.length}" 
    return :NO_NEXT_FIELD
  end
  ##
  # put focus on previous field
  # will cycle by default, unless navigation policy not :CYCLICAL
  # in which case returns :NO_PREV_FIELD.
  # @return [nil, :NO_PREV_FIELD] nil if cyclical and it finds a field
  #  if not cyclical, and no more fields then :NO_PREV_FIELD
  def select_prev_field
    return :UNHANDLED if @focusables.nil? or @focusables.empty?
    #$log.debug "insdie sele prev field :  #{@active_index} WL:#{@widgets.length}" 
    if @active_index.nil?
      @active_index = @focusables.length 
    end

    f = @focusables[@active_index]
    index = @active_index
    if index > 0
      index -= 1
      f = @focusables[index]
      if f
        select_field f
        return
      end
    end

    return :NO_PREV_FIELD
  end
  ##
  # move cursor by num columns. Form
  def addcol num
    return if @col.nil? || @col == -1
    @col += num
    @window.wmove @row, @col
    ## 2010-01-30 23:45 exchange calling parent with calling this forms setrow
    # since in tabbedpane with table i am not gietting this forms offset. 
    #setrowcol nil, col
  end
  ##
  # move cursor by given rows and columns, can be negative.
  # 2010-01-30 23:47 FIXME, if this is called we should call setrowcol like in addcol
  def addrowcol row,col
    return if @col.nil? or @col == -1   # contradicts comment on top - "can be negative"
    return if @row.nil? or @row == -1
    @col += col
    @row += row
    @window.wmove @row, @col
  end

  ## Form
  # New attempt at setting cursor using absolute coordinates
  # Also, trying NOT to go up. let this pad or window print cursor.
  def setrowcol r, c
    @row = r unless r.nil?
    @col = c unless c.nil?
  end
  ##

  # e.g. process_key ch, self
  # returns UNHANDLED if no block for it
  # after form handles basic keys, it gives unhandled key to current field, if current field returns
  # unhandled, then it checks this map.
  # Please update widget with any changes here. TODO: match regexes as in mapper

  def process_key keycode, object
    return _process_key keycode, object, @window
  end

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
  #
  # These mappings will only trigger if the current field
  #  does not use them.
  #
  def map_keys
    return if @keys_mapped
    #bind_key(FFI::NCurses::KEY_F1, 'help') { hm = help_manager(); hm.display_help }
    #bind_key(FFI::NCurses::KEY_F9, "Print keys", :print_key_bindings) # show bindings, tentative on F9
    @keys_mapped = true
  end

  # this forces a repaint of all visible widgets and has been added for the case of overlapping
  # windows, since a black rectangle is often left when a window is destroyed. This is internally
  # triggered whenever a window is destroyed, and currently only for root window.
  # NOTE: often the window itself or spaces between widgets also gets cleared, so basically
  # the window itself may need recreating ? 2014-08-18 - 21:03 
  def repaint_all_widgets
    $log.debug "  REPAINT ALL in FORM called "
    @widgets.each do |w|
      next if w.visible == false
      #next if w.class.to_s == "Canis::MenuBar"
      $log.debug "   ---- REPAINT ALL #{w.name} "
      #w.repaint_required true
      w.repaint_all true
      w.repaint
    end
    $log.debug "  REPAINT ALL in FORM complete "
    #  place cursor on current_widget 
    setpos
  end

  ## forms handle keys
  # mainly traps tab and backtab to navigate between widgets.
  # I know some widgets will want to use tab, e.g edit boxes for entering a tab
  #  or for completion.
  # @throws FieldValidationException
  # NOTE : please rescue exceptions when you use this in your main loop and alert() user
  #
  def handle_key(ch)
    # 2014-08-19 - 21:10 moving to init, so that user may override or remove
    handled = :UNHANDLED # 2011-10-4 

    case ch
    when -1
      return
    when 1000, 12
      # NOTE this works if widgets cover entire screen like text areas and lists but not in 
      #  dialogs where there is blank space. only widgets are painted.
      # testing out 12 is C-l
      $log.debug " form REFRESH_ALL repaint_all HK #{ch} #{self}, #{@name} "
      repaint_all_widgets
      return
    when FFI::NCurses::KEY_RESIZE  # SIGWINCH 
      # note that in windows that have dialogs or text painted on window such as title or 
      #  box, the clear call will clear it out. these are not redrawn.
      lines = Ncurses.LINES
      cols = Ncurses.COLS
      x = Ncurses.stdscr.getmaxy
      y = Ncurses.stdscr.getmaxx
      $log.debug " form RESIZE HK #{ch} #{self}, #{@name}, #{ch}, x #{x} y #{y}  lines #{lines} , cols: #{cols} "
      #alert "SIGWINCH WE NEED TO RECALC AND REPAINT resize #{lines}, #{cols}: #{x}, #{y} "

      # next line may be causing flicker, can we do without.
      Ncurses.endwin
      @window.wrefresh
      @window.wclear
      if @layout_manager
        @layout_manager.do_layout
        # we need to redo statusline and others that layout ignores
      else
        @widgets.each { |e| e.repaint_all(true) } # trying out
      end
      ## added RESIZE on 2012-01-5 
      ## stuff that relies on last line such as statusline dock etc will need to be redrawn.
      fire_handler :RESIZE, self 
    else
      field =  get_current_field
      handled = :UNHANDLED 
      handled = field.handle_key ch unless field.nil? # no field focussable
      $log.debug "handled inside Form #{ch} from #{field} got #{handled}  "
      # some widgets like textarea and list handle up and down
      if handled == :UNHANDLED or handled == -1 or field.nil?
        case ch
        when FFI::NCurses::KEY_TAB, ?\M-\C-i.getbyte(0)  # tab and M-tab in case widget eats tab (such as Table)
          ret = select_next_field
          return ret if ret == :NO_NEXT_FIELD
          # alt-shift-tab  or backtab (in case Table eats backtab)
        when FFI::NCurses::KEY_BTAB, 481 ## backtab added 2008-12-14 18:41 
          ret = select_prev_field
          return ret if ret == :NO_PREV_FIELD
        when FFI::NCurses::KEY_UP
          ret = select_prev_field
          return ret if ret == :NO_PREV_FIELD
        when FFI::NCurses::KEY_DOWN
          ret = select_next_field
          return ret if ret == :NO_NEXT_FIELD
        else
          #$log.debug " before calling process_key in form #{ch}  " if $log.debug? 
          ret = process_key ch, self
          # seems we need to flushinp in case composite has pushed key
          $log.debug "FORM process_key #{ch} got ret #{ret} in #{self}, flushing input "
          # 2014-06-01 - 17:01 added flush, maybe at some point we could do it only if unhandled
          #   in case some method wishes to actually push some keys
          FFI::NCurses.flushinp
          return :UNHANDLED if ret == :UNHANDLED
        end
      elsif handled == :NO_NEXT_FIELD || handled == :NO_PREV_FIELD # 2011-10-4 
        return handled
      end
    end
    $log.debug " form before repaint #{self} , #{@name}, ret #{ret}"
    repaint
    ret || 0  # 2011-10-17 
  end

  # 2010-02-07 14:50 to aid in debugging and comparing log files.
  def to_s; @name || self; end

  ## ADD HERE FORM
end # }}}
