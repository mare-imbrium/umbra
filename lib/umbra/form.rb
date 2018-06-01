require 'umbra/eventhandler'         # for register_events and fire_handler etc
require 'umbra/keymappinghandler'    # for bind_key and process_key
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
##  Events: RESIZE (allows listener to reposition objects that have variable widths or heights)
## NOTE: active_index: 2018-05-17 - is being set to 0 even though no field is active. Thus, first time 
#    on_enter does not fire. It should only be set after a field is focused and its on_enter has succeeded.
#

module Umbra
class Form 
  # array of widgets, and those that can be traversed
  attr_reader :widgets, :focusables

  # related window pointer used for printing or other FFI calls
  attr_accessor :window

  # cursor row and col # 2018-03-20 - this is bad as widgets update it. it should be picked up from focussed widget
  # 2018-03-22 - removing access to it
  #attr_accessor :row, :col

  # index of active widget inside focusables array
  attr_accessor :active_index

  # name given to form for debugging
  attr_accessor :name 

  include EventHandler
  include KeyMappingHandler
  def initialize win, &block
    @window = win
    @widgets = []
    @active_index = nil
    @row = @col = 0                    # 2018-03-07 - umbra
    @focusables = []                   # focusable components
    register_events(:RESIZE)
    instance_eval &block if block_given?
    @name ||= ""                       # for debugging 

    # for storing error message NOT_SURE
    #$error_message ||= Variable.new ""

    map_keys unless @keys_mapped
    $log ||= create_logger '/dev/null'    ## FIXME temporarily adding here. If user has not 
                                          ##  specified a logger, create a quiet one.
  end
  ##
  # Add given widget to widget list and returns self
  # A widget must be added to a Form for it to be painted and focussed.
  # @param [Widget] widget to display on form
  # @return [Form] pointer to self
  def add_widget *widget
    widget.each do |w|
      next if @widgets.include? w
      # NOTE: if form created with nil window (messagebox), then this would have to happen later
      w.graphic = @window if @window # 2018-03-19 - prevent widget from needing to call form back
      $log.warn "Window is nil in form.add_widget" unless @window
      w._form = self    # 2018-04-20 - so that update_focusables can be called.
      @widgets << w
    end
    return self
  end

  # remove a widget from form. 
  # Will not be displayed or focussed.
  # @param [Widget] widget to remove from form
  def remove_widget widget
    @widgets.delete widget
    @focusables.delete widget
  end


  # maintain a list of focusable objects so form can traverse between them easily.
  def update_focusables
    #$log.debug "1 inside update_focusables #{@focusables.count} "
    @focusables = @widgets.select { |w| w.focusable }
    #$log.debug "2  inside update_focusables #{@focusables.count} "
  end

  # Decide layout of objects. User has to call this after creating components
  # More may come here.
  def pack

    update_focusables

    # set up hotkeys for buttons and labels with mnemonics and labels.
    @widgets.each do |w|
      #$log.debug "  FOCUSABLES #{w.name} #{w.to_s} #{w.class}"
      if w.respond_to? :mnemonic
        if w.mnemonic
          ch = w.mnemonic.downcase()[0].ord
          # meta key 
          mch = ?\M-a.getbyte(0) + (ch - ?a.getbyte(0))

          if w.respond_to? :fire
            #$log.debug "  setting hotkey #{mch} to button #{w} "
            self.bind_key(mch, "hotkey for button #{w} ") { w.fire }
          else
            # case of labels and labeled field
            #$log.debug "  setting hotkey #{mch} to field #{w} "
            self.bind_key(mch, "hotkey for field #{w.related_widget} ") { 
              
              #$log.debug "  HOTKEY got key #{mch} : for #{w.related_widget} "
              self.select_field w.related_widget }
          end
        end
      end
    end
    @active_index = 0 if @focusables.size > 0
    # 2018-04-14 - why the repaint here ? commenting off. Gave error in messagbox if no window yet.
    #repaint
    self
  end

  ## set focussed widget to given fld.
  ## This ensures that whenever a widget is given focus, the on_leave of the previous widget 
  ##   is called, and the on_enter of this field is called.
  ## 2018-05-18 - rewrite of select_field which did not call on_leave
  def select_widget fld

    return nil unless fld   ## no focusable

    if fld.is_a? Integer
      fld = @focusables[fld]
    end

    return unless fld.focusable

    ## leave existing widget if there was one
    fw =  @_focussed_widget
    return if fw == fld

    if fw
      on_leave fw
    end


    ## enter given widget
    on_enter fld
    @_focussed_widget = fld
    ix = @focusables.index fld
    @active_index = ix

    @row, @col = fld.rowcol
    _setrowcol @row, @col 
    repaint # 2018-03-21 - handle_key calls repaint, is this for cases not involving keypress ?
    @window.refresh
  end
  alias :select_field :select_widget


  # form repaint,calls repaint on each widget which will repaint it only if it has been modified since last call.
  # called after each keypress and on select_field.

  def repaint
    $log.debug " form repaint:#{self}, #{@name} , r #{@row} c #{@col} " if $log.debug? 
    @widgets.each do |f|
      next if f.visible == false
      #f.repaint 
      # changed on 2018-03-21 - so widgets don't need to do this.
      if f.repaint_required
        f.graphic = @window unless f.graphic   # messageboxes may not have a window till very late
        f.repaint 
        f.repaint_required = false
        f.instance_variable_set(:@_object_created, true)   ## after this property_change handlers will fire
      end
    end

    # get curpos of active widget 2018-03-21 - form is taking control of this now.
    f = get_current_field
    if f
      @row, @col = f.rowcol
      _setpos 
    end
    @window.wrefresh
  end



  # @return [Widget, nil] current field, nil if no focusable field
  ## NOTE 2018-05-17 - this is called by form in the very beginning when no field is actually focussed
  ##   but active_index has been set to 0, so the on_enter has not been executed, but the handle_key
  ##   is invoked.
  def get_current_field

    ##  rewrite on 2018-05-18 - so that on_enter is called for first field
    if @_focussed_widget.nil?             ## when form handle_key first called
      select_widget @focusables.first
    end
    return @_focussed_widget

  end
  alias :current_widget :get_current_field


  # take focus to first focusable field
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




  # put focus on next field
  # will cycle by default, unless navigation policy not :CYCLICAL
  # in which case returns :NO_NEXT_FIELD.
  # 2018-03-07 - UMBRA: let us force user to run validation when he does next field
  def select_next_field
    return :UNHANDLED if @focusables.nil? || @focusables.empty?
    index = nil
    if @_focussed_widget
       index = @focusables.index @_focussed_widget
    end
    index = index ? index+1 : 0
    index = 0 if index >= @focusables.length # CYCLICAL 2018-03-11 - 
    select_widget @focusables[index]
  end


  ##
  # put focus on previous field
  # will cycle by default, unless navigation policy not :CYCLICAL
  # in which case returns :NO_PREV_FIELD.
  # @return [nil, :NO_PREV_FIELD] nil if cyclical and it finds a field
  #  if not cyclical, and no more fields then :NO_PREV_FIELD
  def select_prev_field
    return :UNHANDLED if @focusables.nil? or @focusables.empty?
    index = nil
    if @_focussed_widget
       index = @focusables.index @_focussed_widget
       else
       index = @focusables.length 
    end
    index -= 1
    index = @focusables.length-1 if index < 0 # CYCLICAL 2018-03-11 - 
    select_widget @focusables[index]
  end

  private
  # New attempt at setting cursor using absolute coordinates
  # Also, trying NOT to go up. let this pad or window print cursor.
  # 2018-03-21 - we should prevent other widgets from calling this. Tehy need to set their own offsets
  # so form picks up the correct one.
  # 2018-03-21 - renamed to _setrowcol so other programs calling it will bork.
  def _setrowcol r, c
    @row = r unless r.nil?
    @col = c unless c.nil?
  end
  private
  ## 
  # move cursor to where the fields row and col are
  def _setpos r=@row, c=@col
    #$log.debug "setpos : (#{self.name}) #{r} #{c} XXX"
    ## adding just in case things are going out of bounds of a parent and no cursor to be shown
    return if r.nil? or c.nil?  # added 2009-12-29 23:28 BUFFERED
    return if r<0 or c<0  # added 2010-01-02 18:49 stack too deep coming if goes above screen
    @window.wmove r,c
  end
  ##
  # form's trigger, fired when any widget loses focus
  # NOTE: Do NOT override
  #  This wont get called in editor components in tables, since  they are formless 
  def on_leave f
    return if f.nil? || !f.focusable # added focusable, else label was firing
    $log.debug "Form setting state of #{f.name} to NORMAL"
    f.state = :NORMAL
    # 2018-03-11 - trying out, there can be other things a widget may want to do on entry and exit
    if f.highlight_color_pair || f.highlight_attr
      f.repaint_required = true
    end
    f.on_leave if f.respond_to? :on_leave
  end
  # form calls on_enter of each object.
  # However, if a multicomponent calls on_enter of a widget, this code will
  # not be triggered. The highlighted part
  # 2018-03-07 - NOT_SURE
  def on_enter f
    return if f.nil? || !f.focusable # added focusable, else label was firing 2010-09

    f.state = :HIGHLIGHTED
    # If the widget has a color defined for focussed, set repaint
    #  otherwise it will not be repainted unless user edits !
    if f.highlight_color_pair || f.highlight_attr
      f.repaint_required = true
    end

    f.modified = false
    f.on_enter if f.respond_to? :on_enter
  end


  public

  #
  # NOTE: These mappings will only trigger if the current field
  #  does not use them in handle_key
  #
  def map_keys
    return if @keys_mapped
    #bind_key(FFI::NCurses::KEY_F1, 'help') { hm = help_manager(); hm.display_help }
    #bind_key(FFI::NCurses::KEY_F9, "Print keys", :print_key_bindings) # show bindings, tentative on F9
    @keys_mapped = true
  end

  # repaint all # {{{
  # this forces a repaint of all visible widgets and has been added for the case of overlapping
  # windows, since a black rectangle is often left when a window is destroyed. This is internally
  # triggered whenever a window is destroyed, and currently only for root window.
  # NOTE: often the window itself or spaces between widgets also gets cleared, so basically
  # the window itself may need recreating ? 2014-08-18 - 21:03 
  def repaint_all_widgets
    $log.debug "  REPAINT ALL in FORM called "
    #raise "it has come to repaint_all"
    @widgets.each do |w|
      next if w.visible == false
      #next if w.class.to_s == "Canis::MenuBar"
      $log.debug "   ---- REPAINT ALL #{w.name} "
      w.repaint_required = true
      #w.repaint_all true
      w.repaint
    end
    $log.debug "  REPAINT ALL in FORM complete "
    #  place cursor on current_widget 
    _setpos
  end # }}}


  ## forms handle keys {{{
  # mainly traps tab and backtab to navigate between widgets.
  # I know some widgets will want to use tab, e.g edit boxes for entering a tab
  #  or for completion.
  # @throws FieldValidationException
  # NOTE : please rescue exceptions when you use this in your main loop and alert() user
  #
  def handle_key(ch)
    handled = :UNHANDLED 

    case ch
    when -1
      #repaint # only for continuous updates, and will need to use wtimeout and not nodelay in getch
      return
    when 1000, 18  # what if someone has trapped this.
      # NOTE this works if widgets cover entire screen like text areas and lists but not in 
      #  dialogs where there is blank space. only widgets are painted.
      # testing out 12 is C-l, 18 is C-r
      $log.debug " form REFRESH_ALL repaint_all HK #{ch} #{self}, #{@name} "
      FFI::NCurses.endwin
      @window.wrefresh    ## endwin must be followed by refresh
      @window.repaint
      repaint_all_widgets
      @window.wrefresh
      return 0
    when FFI::NCurses::KEY_RESIZE  # SIGWINCH # UNTESTED XXX
      ## NOTE: this works but boxes are not resized since hardcoded height and width were given.
      ## 2018-05-13 - only if a layout is used, can a recalc happen.
      # note that in windows that have dialogs or text painted on window such as title or 
      #  box, the clear call will clear it out. these are not redrawn.
      
      # next line may be causing flicker, can we do without.
      FFI::NCurses.endwin
      @window.wrefresh
      @window.wclear
      lines = FFI::NCurses.LINES
      cols = FFI::NCurses.COLS
      #x = FFI::NCurses.stdscr.getmaxy
      x = @window.getmaxy
      #y = FFI::NCurses.stdscr.getmaxx
      y = @window.getmaxx
      @window.wresize(x,y)
      $log.debug " form RESIZE SIGWINCH HK #{ch} #{self}, #{@name}, #{ch}, x #{x} y #{y}  lines #{lines} , cols: #{cols} "
      #alert "SIGWINCH WE NEED TO RECALC AND REPAINT resize #{lines}, #{cols}: #{x}, #{y} "

      repaint_all_widgets
      #if @layout_manager
        #@layout_manager.do_layout
        ## we need to redo statusline and others that layout ignores
      #else
      #end
      ## added RESIZE on 2012-01-5 
      ## stuff that relies on last line such as statusline dock etc will need to be redrawn.
      fire_handler :RESIZE, self 
      @window.wrefresh
    else
      field =  get_current_field
      handled = :UNHANDLED 
      handled = field.handle_key ch unless field.nil? # no field focussable
      ## next line "field" can print entire content of a list or table if to_s is large
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
  end # }}}

  # 2010-02-07 14:50 to aid in debugging and comparing log files.
  def to_s; @name || self; end

  ## ADD HERE FORM
end 

end # module
