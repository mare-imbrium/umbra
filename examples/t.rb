#!/usr/bin/env ruby
#
require 'umbra/window'
require 'umbra/form'

begin
  init_curses
  txt = "Press cursor keys to move window"
  win = Window.new
  win.printstr txt
  win.printstr("Press Ctrl-Q to quit", 2, 0)

  win.wrefresh

  form = Form.new win

  ch = 0
  xx = 1
  yy = 1
  y = x = 1
  while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
    #y, x = win.getbegyx(win.getwin)
    old_y, old_x = y, x
    #log win, :y, y, :x, x, :ch, ch, keyname(ch)
    # move 0, 0
    # addstr "y %d x %d" % [y, x]
    case ch
    when FFI::NCurses::KEY_RIGHT
      x += 1
    when FFI::NCurses::KEY_LEFT
      x -= 1
    when FFI::NCurses::KEY_UP
      y -= 1
    when FFI::NCurses::KEY_DOWN
      y += 1
    end
    rv = nil
    #rv = win.mvwin(y, x)
  
    #win.printstr "#{ch.to_s}:#{FFI::NCurses::keyname(ch)}", y, x
    win.printstring y, x, "#{ch.to_s}:#{FFI::NCurses::keyname(ch)}"
    y += 1
    if rv == FFI::NCurses::ERR
      # put the window back
      #rv = mvwin(win, old_y, old_x)
    end

    # tell ncurses we want to refresh stdscr (to erase win's frame)
    #touchwin(stdscr)
    #refresh
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
