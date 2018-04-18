# ----------------------------------------------------------------------------- #
#         File: keymappinghandler.rb
#  Description: methods for mapping methods or blocks to keys
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-04-05 - 08:34
#      License: MIT
#  Last update: 2018-04-17 08:59
# ----------------------------------------------------------------------------- #
#  keymappinghandler.rb  Copyright (C) 2018 j kepler

module Umbra
  module KeyMappingHandler

    # bind a method to a key.
    # @examples
    # -- call cursor_home on pressing C-a. The symbol will also act as documentation for the key
    # bind_key ?C-a, :cursor_home
    # -- call collapse_parent on pressing x. The string will be the documentation for the key
    # bind_key(?x, 'collapse parent'){ collapse_parent() }
    #
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
        raise "unused"
      else
        #$log.debug " assigning #{keycode} to  _key_map for #{self.class}, #{@name}" if $log.debug? 
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
          $log.error "This ( #{self.class} ) does not respond to #{blk.to_s} [PROCESS-KEY]"
          # added 2013-03-05 - 19:50 so called can know
          return :UNHANDLED 
        end
      else
        $log.debug "rwidget BLOCK called _process_key " if $log.debug? 
        return blk.call object,  *@_key_args[keycode]
      end
    end

  end # module KeyMappingHandler
end # module
