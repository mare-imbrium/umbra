module Umbra
  # module containing methods to enable widgets and forms to handle events.
  # Included by form and widget
  module EventHandler 
    # register_events: widgets may register their events prior to calling super {{{
    # This ensures that caller programs don't use wrong event names.
    #
    def register_events eves
      @_events ||= []
      case eves
      when Array
        @_events.push(*eves)
      when Symbol
        @_events << eves
      else
        raise ArgumentError "register_events: Don't know how to handle #{eves.class}"
      end
    end # }}}
    ##
    # bind_event: bind an event to a block, optional args will also be passed when calling {{{
    # 2018-04-01 - renamed +bind+ to +bind_event+
    def bind_event event, *xargs, &blk
      #$log.debug "#{self} called EventHandler BIND #{event}, args:#{xargs} "
      if @_events
        $log.warn "bind: #{self.class} does not support this event: #{event}. #{@_events} " if !event? event
        #raise ArgumentError, "#{self.class} does not support this event: #{event}. #{@_events} " if !event? event
      else
        # it can come here if bind in initial block, since widgets add to @_event after calling super
        # maybe we can change that.
        $log.warn "BIND #{self.class} (#{event})  XXXXX no events defined in @_events. Please do so to avoid bugs and debugging. This will become a fatal error soon."
      end
      @handler ||= {}
      @event_args ||= {}
      @handler[event] ||= []
      @handler[event] << blk
      @event_args[event] ||= []
      @event_args[event] << xargs
    end # }}}

    ##
    # fire_handler: Fire all bindings for given event  {{{
    # e.g. fire_handler :ENTER, self
    # The first parameter passed to the calling block is either self, or some action event
    # The second and beyond are any objects you passed when using `bind` or `command`.
    # Exceptions are caught here itself, or else they prevent objects from updating, usually the error is 
    # in the block sent in by application, not our error.
    # TODO: if an object throws a subclass of VetoException we should not catch it and throw it back for 
    # caller to catch and take care of, such as prevent LEAVE or update etc.
    def fire_handler event, object
      $log.debug "inside def fire_handler evt:#{event}, o: #{object.class}"
      if !@handler.nil?
        if @_events
          raise ArgumentError, "fire_handler: #{self.class} does not support this event: #{event}. #{@_events} " if !event? event
        else
          $log.debug "fire_handler #{self.class}  XXXXX no events defined in @_events "
        end
        ablk = @handler[event]
        if !ablk.nil?
          aeve = @event_args[event]
          ablk.each_with_index do |blk, ix|
            #$log.debug "#{self} called EventHandler firehander #{@name}, #{event}, obj: #{object},args: #{aeve[ix]}"
            # self prints the entire content of list or table!
            $log.debug "EVENTHANDLER: #{self} called EventHandler firehander #{@name}, #{event}"
            begin
              blk.call object,  *aeve[ix]
            rescue FieldValidationException => fve
              # added 2011-09-26 1.3.0 so a user raised exception on LEAVE
              # keeps cursor in same field.
              raise fve
            rescue PropertyVetoException => pve
              # added 2011-09-26 1.3.0 so a user raised exception on LEAVE
              # keeps cursor in same field.
              raise pve
            rescue => ex
              ## some don't have name
              # FIXME this should be displayed somewhere. It just goes into log file quietly.
              $log.error "======= Error ERROR in block event #{self}:  #{event}"
              $log.error ex
              $log.error(ex.backtrace.join("\n")) 
              alert ex.to_s    # added 2018-04-08 - 08:55 so it shows up
              FFI::NCurses.beep    # doesn't do anything, maybe switched off in preferences
            end
          end
        else
          # there is no block for this key/event
          # we must behave exactly as processkey
          # NOTE this is too risky since then buttons and radio buttons
          # that don't have any command don;t update,so removing 2011-12-2 
          #return :UNHANDLED
          return :NO_BLOCK
        end # if
      else
        # there is no handler
        # I've done this since list traps ENTER but rarely uses it.
        # For buttons default, we'd like to trap ENTER even when focus is elsewhere
        # we must behave exactly as processkey
        # NOTE this is too risky since then buttons and radio buttons
        # that don't have any command don;t update,so removing 2011-12-2 
        #return :UNHANDLED
        # If caller wants, can return UNHANDLED such as list and ENTER.
        return :NO_BLOCK
      end # if
    end # }}}

      def fire_property_change text, oldvalue, newvalue
        # canis returns if oldvalue is nil, but if object created with nil and later
        # prop is set then we need a handler fired.
        return if @_object_created.nil? 
        $log.debug " FPC #{self}: #{text} "
        if @pce.nil?
          @pce = PropertyChangeEvent.new(self, text, oldvalue, newvalue)
        else
          @pce.set( self, text, oldvalue, newvalue)
        end
        @repaint_required = true 
        fire_handler :PROPERTY_CHANGE, @pce
      end

  ## Created and sent to all listeners whenever a property is changed
  # @see fire_property_change
  # @see fire_handler 
  # @since 1.0.5 added 2010-02-25 23:06 
  class PropertyChangeEvent # {{{
    attr_accessor :source, :property_name, :oldvalue, :newvalue
    def initialize source, property_name, oldvalue, newvalue
      set source, property_name, oldvalue, newvalue
    end
    def set source, property_name, oldvalue, newvalue
        @source, @property_name, @oldvalue, @newvalue =
        source, property_name, oldvalue, newvalue
    end
    def to_s
      "PROPERTY_CHANGE name: #{property_name}, oldval: #{@oldvalue}, newvalue: #{@newvalue}, source: #{@source}"
    end
    def inspect
      to_s
    end
  end # }}}

    # event? : returns boolean depending on whether this widget has registered the given event {{{
    def event? eve
      @_events.include? eve
    end # }}}

    # The property change is not acceptable, undo it. e.g. test2.rb
    # @param [String] text message
    # @param [Event] PropertyChangeEvent object
    # @since 1.4.0
    class PropertyVetoException < RuntimeError
      def initialize(string, event)
        @string = string
        @event = event
        super(string)
      end
      attr_reader :string, :event
    end

# ActionEvent # {{{
    # source - as always is the object whose event has been fired
    # id     - event identifier (seems redundant since we bind events often separately.
    # event  - is :PRESS
    # action_command - command string associated with event (such as title of button that changed
    ActionEvent = Struct.new(:source, :event, :action_command) do
      # This should always return the most relevant text associated with this object
      # so the user does not have to go through the source object's documentation.
      # It should be a user-friendly string 
      # @return text associated with source (label of button)
      def text
        source.text
      end

      # This is similar to text and can often be just an alias.
      # However, i am putting this for backward compatibility with programs
      # that received the object and called it's getvalue. It is better to use text.
      # @return text associated with source (label of button)
      def getvalue
        raise "getvalue in eventhandler. remove if does not happen in 2018"
        source.getvalue
      end
    end # }}}
  end # module eventh 
end # module
