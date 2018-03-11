
  class Button < Widget 
    attr_accessor :surround_chars   # characters to use to surround the button, def is square brackets
    # char to be underlined, and bound to Alt-char
    attr_accessor :mnemonic
    def initialize config={}, &block
      #require 'canis/core/include/ractionevent'
      @focusable = true
      @editable = false
      # hotkey denotes we should bind the key itself not alt-key (for menulinks)
      @hotkey = config.delete(:hotkey) 
      #register_events([:PRESS, :FORM_ATTACHED])
      @default_chars = ['> ', ' <'] 
      super


      @surround_chars ||= ['[ ', ' ]'] 
      @col_offset = @surround_chars[0].length 
      @text_offset = 0
      map_keys
    end
    ##
    # set button based on Action
    def action a
      text a.name
      mnemonic a.mnemonic unless a.mnemonic.nil?
      command { a.call }
    end
    ##
    # button:  sets text, checking for ampersand, uses that for hotkey and underlines
    def OLDtext(*val)
      if val.empty?
        return @text
      else
        s = val[0].dup
        s = s.to_s if !s.is_a? String  # 2009-01-15 17:32 
        if (( ix = s.index('&')) != nil)
          s.slice!(ix,1)
          @underline = ix #unless @form.nil? # this setting a fake underline in messageboxes
          @text = s # mnemo needs this for setting description
          mnemonic s[ix,1]
        end
        @text = s
      end
      return self 
    end

    ## 
    # FIXME this will not work in messageboxes since no form available
    # if already set mnemonic, then unbind_key, ??
    # NOTE: Some buttons like checkbox directly call mnemonic, so if they have no form
    # then this processing does not happen

    # set mnemonic for button, this is a hotkey that triggers +fire+ upon pressing Alt+char
    def mnemonic char=nil
      return @mnemonic unless char  # added 2011-11-24 so caller can get mne

      unless @form
        # we have some processing for when a form is attached, registering a hotkey
        bind(:FORM_ATTACHED) { mnemonic char }
        return self # added 2014-03-23 - 22:59 so that we can chain methods
      end
      @mnemonic = char
      ch = char.downcase()[0].ord ##  1.9 
      # meta key 
      ch = ?\M-a.getbyte(0) + (ch - ?a.getbyte(0)) unless @hotkey
      $log.debug " #{self} setting MNEMO to #{char} #{ch}, #{@hotkey} "
      _t = self.text || self.name || "Unnamed #{self.class} "
      @form.bind_key(ch, "hotkey for button #{_t} ") { |_form, _butt| self.fire }
      return self # added 2015-03-23 - 22:59 so that we can chain methods
    end

    def default_button tf=nil
      return @default_button unless tf
      raise ArgumentError, "default button must be true or false" if ![false,true].include? tf
      unless @form
        bind(:FORM_ATTACHED){ default_button(tf) }
        return self
      end
      $log.debug "XXX:  BUTTON DEFAULT setting to true : #{tf} "
      @default_button = tf
      if tf
        @surround_chars = @default_chars
        @form.bind_key(13, "fire #{self.text} ") { |_form, _butt| self.fire }
      else
        # i have no way of reversing the above
      end
    end

    def getvalue
      @text
    end

    # ensure text has been passed or action
    def getvalue_for_paint
      ret = getvalue
      @text_offset = @surround_chars[0].length
      @surround_chars[0] + ret + @surround_chars[1]
    end

    # FIXME 2014-05-31 since form checks for highlight color and sets repaint on on_enter, we shoul not set it.
    #   but what if it is set at form level ?
    #    also it is not correct to set colors now that form's defaults are taken
    def repaint  # button

        $log.debug("BUTTON repaint : #{self}  r:#{@row} c:#{@col} , cp:#{@color_pair}, st:#{@state}, #{getvalue_for_paint}" )
        r,c = @row, @col 
        _attr = @attr || NORMAL
        _color = @color_pair
        if @state == :HIGHLIGHTED
          _color = @highlight_color_pair || @color_pair
          _attr = REVERSE #if _color == @color_pair
        elsif selected? # only for certain buttons lie toggle and radio
          _color = @selected_color_pair || @color_pair
        end
        $log.debug "XXX: button #{text}   STATE is #{@state} color #{_color} , attr:#{_attr}"
        value = getvalue_for_paint
        $log.debug("button repaint :#{self} r:#{r} c:#{c} col:#{_color} v: #{value} ul #{@underline} mnem #{@mnemonic} ")
        len = @width || value.length
        @graphic = @form.window if @graphic.nil? ## cell editor listbox hack 
        @graphic.printstring r, c, "%-*s" % [len, value], _color, _attr
#       @form.window.mvchgat(y=r, x=c, max=len, Ncurses::A_NORMAL, bgcolor, nil)
        # in toggle buttons the underline can change as the text toggles
        if @underline || @mnemonic
          uline = @underline && (@underline + @text_offset) ||  value.index(@mnemonic) || 
            value.index(@mnemonic.swapcase)
          # if the char is not found don't print it
          if uline
            y=r #-@graphic.top
            x=c+uline #-@graphic.left
            #
            # NOTE: often values go below zero since root windows are defined 
            # with 0 w and h, and then i might use that value for calcaluting
            #
            $log.error "XXX button underline location error #{x} , #{y} " if x < 0 or c < 0
            raise " #{r} #{c}  #{uline} button underline location error x:#{x} , y:#{y}. left #{@graphic.left} top:#{@graphic.top} " if x < 0 or c < 0
            @graphic.mvchgat(y, x, max=1, Ncurses::A_BOLD|Ncurses::A_UNDERLINE, _color, nil)
          end
        end
    end

    ## command of button (invoked on press, hotkey, space)
    # added args 2008-12-20 19:22 
    def command *args, &block
      bind :PRESS, *args, &block
    end
    ## fires PRESS event of button
    def fire
      #$log.debug "firing PRESS #{text}"
      fire_handler :PRESS, ActionEvent.new(self, :PRESS, text)
    end
    # for campatibility with all buttons, will apply to radio buttons mostly
    def selected?; false; end

    def map_keys
      return if @keys_mapped
      bind_key(32, "fire") { fire } if respond_to? :fire
    end

    # Button
    def handle_key ch
      super
    end
=begin
      case ch
      when FFI::NCurses::KEY_LEFT, FFI::NCurses::KEY_UP
        return :UNHANDLED
        #  @form.select_prev_field
      when FFI::NCurses::KEY_RIGHT, FFI::NCurses::KEY_DOWN
        return :UNHANDLED
        #  @form.select_next_field
      # 2014-05-07 - 12:26 removed ENTER on buttons
        #  CANIS : button only responds to SPACE, ENTER will only work on default button.
      #when FFI::NCurses::KEY_ENTER, 10, 13, 32  # added space bar also
        # I am really confused about this. Default button really confuses things in some 
        # situations, but is great if you are not on the buttons.
        # shall we keep ENTER for default button
      when 32  # added space bar also
        if respond_to? :fire
          fire
        end
      else
        if $key_map_type == :vim
          case ch
          when ?j.getbyte(0)
            @form.window.ungetch(KEY_DOWN)
            return 0
          when ?k.getbyte(0)
            @form.window.ungetch(KEY_UP)
            return 0
          end

        end
        return :UNHANDLED
      end
    end
=end

    # temporary method, shoud be a proper class
    def self.button_layout buttons, row, startcol=0, cols=Ncurses.COLS-1, gap=5
      col = startcol
      buttons.each_with_index do |b, ix|
        $log.debug " BUTTON #{b}: #{b.col} "
        b.row = row
        b.col col
        $log.debug " after BUTTON #{b}: #{b.col} "
        len = b.text.length + gap
        col += len
      end
    end
  end #BUTTON # }}}
