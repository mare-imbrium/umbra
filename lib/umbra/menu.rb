# ----------------------------------------------------------------------------- #
#         File: menu.rb
#  Description: a popup menu like mc/midnight commander 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-13
#      License: MIT
#  Last update: 2018-06-01 12:38
# ----------------------------------------------------------------------------- #
#  menu.rb  Copyright (C) 2012-2018 j kepler

# a midnight commander like mc_menu
# Pass a hash of key and label.
# menu will only accept keys or arrow keys or C-c Esc to cancel
# returns nil if C-c or Esc pressed.
# Otherwise returns character pressed.
# == Todo 
# depends on our window class which is minimal.
# [ ] cursor should show on the row that is highlighted
# [ ] Can we remove that dependency so this is independent
# Currently, we paint window each time user pressed up or down, but we can just repaint the attribute
# [ ] width of array items not checked. We could do that or have user pass it in.
# [ ] we are not scrolling if user sends in a large number of items. we should cap it to 10 or 20
# == CHANGELOG
#
require 'umbra/window'
module Umbra
  class Menu

    def initialize title, hash, config={}

      @list = hash.values
      @keys = hash.keys.collect { |x| x.to_s }
      @hash = hash
      bkgd = config[:bkgd] || FFI::NCurses.COLOR_PAIR(14) | BOLD
      @attr = BOLD
      @color_pair = config[:color_pair] || 14
      ht = @list.size+2
      wid = config[:width] || 40
      top = (FFI::NCurses.LINES - ht)/2
      left = (FFI::NCurses.COLS - wid)/2
      @window = Window.new(ht, wid, top, left)
      @window.wbkgd(bkgd)
      @window.box
      @window.title(title)
      @current = 0
      print_items @hash
    end
    def print_items hash
      ix = 0
      hash.each_pair {|k, val|
        attr = @attr
        attr = REVERSE if ix == @current
        @window.printstring(ix+1 , 2, "#{k}    #{val}", @color_pair, attr )
        ix += 1
      }
      @window.refresh
    end
    def getkey
      ch = 0
      char = nil
      begin
        while (ch = @window.getkey) != FFI::NCurses::KEY_CTRL_C
          break if ch == 27 # ESC
          tmpchar = FFI::NCurses.keyname(ch) rescue '?'
          if @keys.include? tmpchar
            $log.debug "  menu #{tmpchar.class}:#{tmpchar} "
            char = ch.chr
            $log.debug "  menu #{ch.class}:#{char} "
            #char = tmpchar
            break
          end
          case ch
          when FFI::NCurses::KEY_DOWN
            @current += 1
          when FFI::NCurses::KEY_UP
            @current -= 1
          when FFI::NCurses::KEY_RETURN
            char = @keys[@current]
            break
          end
          @current = 0 if @current < 0
          @current = @list.size-1 if @current >= @list.size
          print_items @hash

          # trap arrow keys here
        end
      ensure
        @window.destroy
      end
      return char
    end
  end
end # module
