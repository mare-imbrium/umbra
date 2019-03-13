#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: ,,F
#  Description: This file does the following:
#       Author:  r kumar
#         Date: ,,D
#  Last update: 2019-03-11 09:54
#      License: MIT License
# ----------------------------------------------------------------------------- #
require 'umbra'
require 'umbra/label'
require 'umbra/tabular'
require 'umbra/listbox'
require 'umbra/textbox'
require 'umbra/box'

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
  statusline(win, "Press Ctrl-q to quit #{win.height}:#{win.width}", 20)
  title = Label.new( :text => "Demo of Tabular", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1,
                    :justify => :center, :color_pair => 0)

  form = Form.new win
  form.add_widget title

  box = Box.new row: 2, col: 0, width: 10, height: 7
  t = Tabular.new(['a', 'b'], [1, 2], [3, 4], [5,6])
  lb = Listbox.new list: t.render
  box.fill lb
  box1 = Box.new row: box.row + box.height + 0, col: box.col, width: 10, height: 7
  t = Tabular.new ['a', 'b']
  t << [1, 2]
  t << [3, 4]
  t << [4, 6]
  t << [8, 6]
  t << [2, 6]
  t.y = '| '
  t.x = '+-'
  lb1 = Listbox.new list: t.render
  box1.fill lb1

  #file = File.expand_path("examples/tasks.csv", __FILE__)
  file = File.expand_path("examples/tasks.csv")
    lines = File.open(file,'r').readlines
    heads = %w[ id sta type prio title ]
    t = Tabular.new do |t|
      t.headings = heads
      t.y = ' '
      lines.each { |e| t.add_row e.chomp.split '|'   }
    end

    t = t.render
    wid = t[0].length + 2
    wid = 30
    box2 = Box.new title: "tasks.csv", row: box.row , col: box.col + box.width+1, width: FFI::NCurses.COLS-box.width-1, height: FFI::NCurses.LINES-1-box.row
  lb2 = Listbox.new list: t

  r = `ls -l`
  res = r.split("\n")

  t = Tabular.new do
    self.headings = 'User',  'Size', 'Mon', 'Date', 'Time', 'File'
    res.each { |e|
      cols = e.split
      next if cols.count < 6
      cols = cols[3..-1]
      cols = cols[0..5] if cols.count > 6
      add_row cols
    }
    column_width 1, 6
    column_align 1, :right
  end
  #t.y = '| '
  #t.x = '+-'
  tb = Textbox.new list: t.render
  box2.add lb2, tb

  form.add_widget box, lb
  form.add_widget box1, lb1
  form.add_widget box2, lb2, tb


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
