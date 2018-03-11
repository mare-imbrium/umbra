#!/usr/bin/env ruby
# example showing labels and fields and buttons
# 2018-03-11 
require './window.rb'
require './label.rb'
require './field.rb'
require './button.rb'

def startup
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Time.now.to_s
    $log.info "Button demo #{$0} started on #{today}"
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
  title = Label.new( :text => "Demo of Fields", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1, 
                    :justify => :center, :color_pair => 0)

  catch(:close) do
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
    w.attr = BOLD
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
    w.attr = REVERSE
    form.add_widget w
  }
  ok_butt = Button.new( :name => 'ok', :text => 'Ok', :row => row+2, :col => col, :width => 10 , :color_pair => 1)
  cancel_butt = Button.new( :name => 'cancel', :text => 'Cancel', :row => row+2, :col => col + 20, :width => 10 , :color_pair => 1)
  form.add_widget ok_butt
  form.add_widget cancel_butt
  cancel_butt.command do
    throw :close
  end
  ok_butt.command do
    form.focusables.each_with_index {|f, ix| 
      if f.class.to_s == "Field"
        $log.debug "FIELD #{f.name} = #{f.text}"
      else
        $log.debug "WIDGET #{f.class.to_s}, #{f.name} = #{f.text}"
      end
    }
    throw :close
  end
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
  end # close

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
