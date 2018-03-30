#!/usr/bin/env ruby
# example showing listbox
# 2018-03-19 -
require 'umbra/window'
require 'umbra/label'
require 'umbra/listbox'
require 'umbra/togglebutton'

def startup
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Time.now.to_s
    $log.info "listbox demo #{$0} started on #{today}"
    FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK,   FFI::NCurses::GREEN) # statusline
end
def statusline win, str, col = 1
  # LINES-2 prints on second last line so that box can be seen
  win.printstring( FFI::NCurses.LINES-2, col, str, 6, REVERSE)
end
begin
  init_curses
  startup
  #win = Window.new
  win = Window.new #20,100, 0, 20
  statusline(win, " "*(win.width-0), 0)
  win.box
  statusline(win, "Press C-q to quit #{win.height}:#{win.width}", 20)
  str = " Demo of listbox "
  win.title str
  alist = ["one item"*4, "another item"*10, "yet another item"*15]
  #alist = []
  (1..50).each do |i|
    alist << "#{i} entry"
  end

  # check with only a few rows - DONE
  # check with exactly 20 rows
  # check with long lines
  catch(:close) do
    form = Form.new win
    win.printstring(3,1,"Just testing that listbox is correctly positioned")
    lb = Listbox.new list: alist, row: 4, col: 2, width: 50, height: 20
    win.printstring(lb.row+1,0,"XX")
    win.printstring(lb.row+1,lb.col+lb.width,"XX")
    win.printstring(lb.row+lb.height,1,"This prints below the listbox")
    brow = lb.row+lb.height+3
    tb = ToggleButton.new onvalue: "Border", offvalue: "No Border", row: brow, col: 10, value: true

    tb.command do
      if tb.value
        lb.border true
      else
        lb.border false
      end
      lb.repaint_required true
    end
    form.add_widget lb
    form.add_widget tb
    form.pack
    form.select_first_field
    win.wrefresh

    y = x = 1
    while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
      begin
        form.handle_key ch
      rescue => e
        puts e
        puts e.backtrace.join("\n")
      end
      win.wrefresh
    end
  end # close

rescue => e
  win.destroy if win
  win = nil
  FFI::NCurses.endwin
  puts e
  puts e.backtrace.join("\n")
ensure
  win.destroy if win
  FFI::NCurses.endwin
  if e
    puts e 
    puts e.backtrace.join("\n")
  end
end
