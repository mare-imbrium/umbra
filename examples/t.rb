#!/usr/bin/env ruby
#
require 'umbra'
require 'umbra/form'

def startup
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Date.today
    $log.info "Started up on #{today}"
    FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK,   FFI::NCurses::GREEN) # statusline
end
begin
  include Umbra
  init_curses
  startup
  txt = "Demo of keys. Press various keys to see what value comes"
  win = Window.new
  win.printstr txt
  win.printstr("Press Ctrl-Q to quit", 2, 0)

  win.wrefresh

  form = Form.new win

  ch = 0
  y = x = 1
  while (ch = win.getch) != FFI::NCurses::KEY_CTRL_Q
    if ch == 2727 or ch == -1
      $log.debug "t.rb got #{ch}"
      break
    end
    rv = nil
    #rv = win.mvwin(y, x)
  
    case ch
    when Integer
      win.printstring y, x, "#{ch.to_s}:#{FFI::NCurses::keyname(ch)}"
    when String
      win.printstring y, x, "#{ch.to_s}"
    end
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
