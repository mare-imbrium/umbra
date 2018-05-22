#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: extab2.rb
#  Description: 
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-05-06 - 11:20
#      License: MIT
#  Last update: 2018-05-22 23:05
# ----------------------------------------------------------------------------- #
#  extab2.rb  Copyright (C) 2018 j kepler
require 'umbra'
require 'umbra/label'
require 'umbra/tabular'
require 'umbra/listbox'
require 'umbra/textbox'
require 'umbra/box'
require 'umbra/table'

def startup
  require 'date'

  $log = create_logger "v.log"
  #$log.level = Logger::DEBUG
  today = Date.today
  $log.info "Started demo table on #{today}"
end
def statusline win, str, col = 0
  win.printstring( FFI::NCurses.LINES-1, col, str, 5)
end
begin
  include Umbra
  init_curses
  startup
  win = Window.new
  statusline(win, " "*(win.width-0), 0)
  statusline(win, "Press C-q to quit #{win.height}:#{win.width}", 20)
  title = Label.new( :text => "Demo of Table", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1, 
                    :justify => :center, :color_pair => 0)

  form = Form.new win
  form.add_widget title

  box = Box.new row: 2, col: 0, width: 15, height: 7
=begin
  t = Tabular.new(['a', 'b'], [1, 2], [3, 4], [5,6])
  lb = Listbox.new list: t.render
=end
  #table = Table.new(['a', 'b'], [1, 2], [3, 4], [5,6])
  table = Table.new(columns: ['a', 'b'], data: [[1, 2], [3, 4], [5,6]])
  box.fill table
  box1 = Box.new row: box.row + box.height + 0, col: box.col, width: box.width, height: 7
  table1 = Table.new columns: ['a', 'b']
  table1 << [8, 6]
  table1 << [1, 2]
  table1 << [3, 4]
  table1 << [4, 6]
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
    # testing out coloring different rows in different colors depending on status
    def t.color_of_row index, state
      arr = super
      if index == 0                  ## header
        arr = @header_color_pair || [ CP_MAGENTA, REVERSE ]
      elsif data[index-1][1] == "clo"
        arr = [ CP_BLUE, NORMAL ]
      elsif self.data[index-1][1] == "ope"
        arr = [ CP_YELLOW, BOLD ]
      end
      arr
    end
    #t.column_width 4, 15            ## checking truncate of long data

    #t.render
    box2 = Box.new title: "tasks.csv", row: box.row , col: box.col + box.width+1, width: FFI::NCurses.COLS-box.width-1, height: FFI::NCurses.LINES-1-box.row
  #lb2 = Listbox.new list: t

    table2 = t
    #box2.fill table2

  r = `ls -l`
  res = r.split("\n")

  table3 = Table.new do
    self.headings = 'User',  'Size', 'Mon', 'Date', 'Time', 'File'
    self.header_color_pair = [ CP_CYAN, REVERSE ]
    res.each { |e|
      cols = e.split
      next if cols.count < 6
      cols = cols[3..-1]
      cols = cols[0..5] if cols.count > 6
      add_row cols
    }
    column_width 1, 10
    #column_width 5, 10   ## testing truncate
    column_align 1, :right
    column_align 3, :right
  end

  # testing out coloring different columns in different color
  ## NOTE that as we scroll the colors will change for a column
  ##   We don't know which columns have come in since scrolling will cut off some columns.
  ##   We need to access pcol to find out which the starting column is, so which know which columns
  ##   we actually have.
  def table3.print_row(win, row, col, str, index, state)
    f = str.split('|')
    attrib = NORMAL
    attrib = BOLD if index == 0
    attrib = REVERSE if state == :HIGHLIGHTED
    f.each_with_index {|c, ix|
      win.printstring(row, col, c, ix+1, attrib)
      col += c.length+1
    }

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
  main_loop(form) do |ch|
    statusline(win, "Pressed #{ch} on     ", 70)
    form.handle_key ch
    win.wrefresh
  end
=begin
  while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
    next if ch == -1
    form.handle_key ch
    #statusline(win, "Pressed #{ch} on     ", 70)
    win.wrefresh
  end
=end

rescue Object => e
  @window.destroy if @window
  FFI::NCurses.endwin
  puts e
  puts e.backtrace.join("\n")
ensure
  @window.destroy if @window
  $log.close if $log
  FFI::NCurses.endwin
  puts 
end
