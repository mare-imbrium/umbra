require 'umbra'

## Basic hello world program

begin
  include Umbra
  init_curses
  win = Window.new
  win.printstring(10,10, "Hello World!");
  win.wrefresh

  win.getchar

ensure
  win.destroy
  FFI::NCurses.endwin
end
