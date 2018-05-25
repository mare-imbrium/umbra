#!/usr/bin/env ruby
# 2018-05-24 
require 'umbra'
require 'umbra/label'

begin
  include Umbra
  init_curses
  #$log = create_logger '/dev/null'
  win = Window.new
  title = Label.new( :text => "Demo of Labels", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1, 
                    :justify => :center, :color_pair => 0)

  form = Form.new win
  form.add_widget title
  form.pack
  form.repaint
  win.wrefresh

  while (ch = win.getkey) != 113
    next if ch == -1
    win.wrefresh
  end

ensure
  win.destroy
  FFI::NCurses.endwin
end
