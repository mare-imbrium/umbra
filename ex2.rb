#!/usr/bin/env ruby
# example showing only labels and fields a window
# 2018-03-10 
require './window.rb'
require './label.rb'
require './field.rb'

def startup
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Date.today
    $log.info "Field demo #{$0} started on #{today}"
    FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK,   FFI::NCurses::GREEN) # statusline
end
def statusline win, str, col = 0
  win.printstring( FFI::NCurses.LINES-1, col, str, 10)
end
begin
  init_curses
  startup
  win = Window.new
  statusline(win, " "*(win.width-0), 0)
  statusline(win, "Press q to quit #{win.height}:#{win.width}", 20)
  title = Label.new( :text => "Demo of Labels", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1, 
                    :justify => :center, :color_pair => 0)

  form = Form.new win
  form.add_widget title
  labels = ["Name: ", "Address: ","Mobile No.", "Email Id:","Hobbies: "]
  labs = []
  row = 3
  col = 5
  labels.each_with_index {|lab, ix| 
    w = Label.new( :text => lab, :row => row, :col => col )
    labs << w
    row += 2
    w.color_pair = 1
    w.attr = FFI::NCurses::A_BOLD
    form.add_widget w
  }
  labels = ["Roger Federer", "20 Slam Drive","9810012345", "ihumble@tennis.com","golf, programming"]
  labels = ["name", "address","mobile", "email","hobbies"]
 
  row = 3
  col = 30
  labels.each_with_index {|lab, ix| 
    w = Field.new( :name => lab, :row => row, :col => col , :width => 50)
    labs << w
    row += 2
    w.color_pair = 1
    w.attr = FFI::NCurses::A_REVERSE
    form.add_widget w
  }
  form.pack
  form.select_first_field
  win.wrefresh

  y = x = 1
  while (ch = win.getkey) != 113
    begin
      form.handle_key ch
    rescue => e
      puts e
      puts e.backtrace.join("\n")
    end
    win.wrefresh
  end

rescue => e
  win.destroy if win
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
