  ##
  # The preferred way of printing text on screen, esp if you want to modify it at run time.
  # Use display_length to ensure no spillage.
  # This can use text or text_variable for setting and getting data (inh from Widget).
  # 2011-11-12 making it simpler, and single line only. The original multiline label
  #    has moved to extras/multilinelabel.rb
  #
  class Label < Widget # {{{
    #dsl_accessor :mnemonic       # keyboard focus is passed to buddy based on this key (ALT mask)

    # justify required a display length, esp if center.
    attr_accessor   :justify        #:right, :left, :center
    #dsl_property :display_length #please give this to ensure the we only print this much
    # for consistency with others 2011-11-5 
    #alias :width :display_length
    #alias :width= :display_length=

    def initialize form, config={}, &block
  
      @text = config.fetch(:text, "NOTFOUND")
      @editable = false
      @focusable = false
      # we have some processing for when a form is attached, registering a hotkey
      #register_events :FORM_ATTACHED
      super
      @justify ||= :left
      @name ||= @text
      @repaint_required = true
    end
    #
    # get the value for the label
    def getvalue
      #@text_variable && @text_variable.value || @text
      @text
    end
    def label_for field
      @label_for = field
      #$log.debug " label for: #{@label_for}"
      if @form
        bind_hotkey 
      else
      # we have some processing for when a form is attached, registering a hotkey
        bind(:FORM_ATTACHED){ bind_hotkey }
      end
    end

    ## {{{
    # for a button, fire it when label invoked without changing focus
    # for other widgets, attempt to change focus to that field
    def bind_hotkey
      if @mnemonic
        ch = @mnemonic.downcase()[0].ord   ##  1.9 DONE 
        # meta key 
        mch = ?\M-a.getbyte(0) + (ch - ?a.getbyte(0))  ## 1.9
        if (@label_for.is_a? Canis::Button ) && (@label_for.respond_to? :fire)
          @form.bind_key(mch, "hotkey for button #{@label_for.text} ") { |_form, _butt| @label_for.fire }
        else
          $log.debug " bind_hotkey label for: #{@label_for}"
          @form.bind_key(mch, "hotkey for label #{text} ") { |_form, _field| @label_for.focus }
        end
      end
    end # }}}

    ##
    # label's repaint - I am removing wrapping and Array stuff and making it simple 2011-11-12 
    def repaint
      return unless @repaint_required
      raise "Label row or col nil #{@row} , #{@col}, #{@text} " if @row.nil? || @col.nil?
      r,c = rowcol

      # value often nil so putting blank, but usually some application error
      value = getvalue_for_paint || ""

      if value.is_a? Array
        value = value.join " "
      end
      # ensure we do not exceed
      if @width
        if value.length > @width
          value = value[0..@width-1]
        end
      end
      len = @width || value.length
      #acolor = @color_pair || get_color($datacolor, _color, _bgcolor)
      acolor = @color_pair 
      #$log.debug "label :#{@text}, #{value}, r #{r}, c #{c} col= #{@color}, #{@bgcolor} acolor  #{acolor} j:#{@justify} dlL: #{@width} "
      str = @justify.to_sym == :right ? "%*s" : "%-*s"  # added 2008-12-22 19:05 
    
      @graphic ||= @form.window
      # clear the area
      @graphic.printstring r, c, " " * len , acolor, attr()
      if @justify.to_sym == :center
        padding = (@width - value.length)/2
        value = " "*padding + value + " "*padding # so its cleared if we change it midway
      end
      @graphic.printstring r, c, str % [len, value], acolor, attr()
      if @mnemonic
        ulindex = value.index(@mnemonic) || value.index(@mnemonic.swapcase)
        @graphic.mvchgat(y=r, x=c+ulindex, max=1, Ncurses::A_BOLD|Ncurses::A_UNDERLINE, acolor, nil)
      end
      @repaint_required = false
    end
    # Added 2011-10-22 to prevent some naive components from putting focus here.
    def on_enter
      raise "Cannot enter Label"
    end
    def on_leave
      raise "Cannot leave Label"
    end
  # ADD HERE LABEL
  end # }}}
