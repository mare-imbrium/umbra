#!/usr/bin/env ruby
#
require 'umbra'
require 'umbra/form'

begin
  include Umbra
  init_curses
  txt = "Demo of keys. Press various keys to see what value comes"
  win = Window.new
  win.printstr txt
  win.printstr("Press Ctrl-Q to quit", 2, 0)

  win.wrefresh

  form = Form.new win

  ch = 0
  y = x = 1
  while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
    rv = nil
    #rv = win.mvwin(y, x)
  
    win.printstring y, x, "#{ch.to_s}:#{FFI::NCurses::keyname(ch)}"
    y += 1
    # start a new column if we exceed last line
    if y >= FFI::NCurses.LINES-1
      y = 1
      x += 10
    end

    win.wrefresh
  end

rescue Object => e
  @window.destroy if @window
  FFI::NCurses.endwin
  puts e
  puts e.backtrace.join("\n")
ensure
  @window.destroy if @window
  FFI::NCurses.endwin
  puts 
end
