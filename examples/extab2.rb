#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: extab2.rb
#  Description: 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-05-06 - 11:20
#      License: MIT
#  Last update: 2018-05-06 12:32
# ----------------------------------------------------------------------------- #
#  YFF Copyright (C) 2012-2018 j kepler
require 'umbra'
require 'umbra/label'
require 'umbra/tabular'
require 'umbra/listbox'
require 'umbra/textbox'
require 'umbra/box'
require 'umbra/table'

def startup
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Date.today
    $log.info "Started demo tabular on #{today}"
    FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK,   FFI::NCurses::GREEN) # statusline
end
def statusline win, str, col = 0
  win.printstring( FFI::NCurses.LINES-1, col, str, 10)
end
begin
  include Umbra
  init_curses
  startup
  win = Window.new
  statusline(win, " "*(win.width-0), 0)
  statusline(win, "Press q to quit #{win.height}:#{win.width}", 20)
  title = Label.new( :text => "Demo of Table", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1, 
                    :justify => :center, :color_pair => 0)

  form = Form.new win
  form.add_widget title

  box = Box.new row: 2, col: 0, width: 10, height: 7
=begin
  t = Tabular.new(['a', 'b'], [1, 2], [3, 4], [5,6])
  lb = Listbox.new list: t.render
=end
  table = Table.new(['a', 'b'], [1, 2], [3, 4], [5,6])
  #table.render
  box.fill table
  box1 = Box.new row: box.row + box.height + 0, col: box.col, width: 10, height: 7
  table1 = Table.new ['a', 'b']
  table1 << [1, 2]
  table1 << [3, 4]
  table1 << [4, 6]
  table1 << [8, 6]
  table1 << [2, 6]
  table1.y = '| '
  table1.x = '+-'
  #lb1 = Listbox.new list: t.render
  #table1.render
  box1.fill table1

  #file = File.expand_path("examples/tasks.csv", __FILE__)
  file = File.expand_path("examples/tasks.csv")
    lines = File.open(file,'r').readlines
    heads = %w[ id sta type prio title ]
    t = Table.new do |t|
      t.headings = heads
      t.y = ' '
      lines.each { |e| t.add_row e.chomp.split '|'   }
    end
    t.tabular.use_separator = false

    #t.render
    box2 = Box.new title: "tasks.csv", row: box.row , col: box.col + box.width+1, width: FFI::NCurses.COLS-box.width-1, height: FFI::NCurses.LINES-1-box.row
  #lb2 = Listbox.new list: t

    table2 = t
    #box2.fill table2

  r = `ls -l`
  res = r.split("\n")

  table3 = Table.new do
    self.headings = 'User',  'Size', 'Mon', 'Date', 'Time', 'File'
    res.each { |e|
      cols = e.split
      next if cols.count < 6
      cols = cols[3..-1]
      cols = cols[0..5] if cols.count > 6
      add_row cols
    }
    column_width 1, 6
    align_column 1, :right
  end
  #table3.render
  #t.y = '| '
  #t.x = '+-'
  #tb = Textbox.new list: t.render
  box2.add table2, table3

  form.add_widget box, table
  form.add_widget box1, table1
  form.add_widget box2, table2, table3


  form.pack
  form.repaint
  win.wrefresh

  y = x = 1
  while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
    next if ch == -1
    form.handle_key ch
    #statusline(win, "Pressed #{ch} on     ", 70)
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
