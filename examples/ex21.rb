#!/usr/bin/env ruby
# example showing labeledfield
# 2018-03-10 
require 'umbra'
require 'umbra/label'
require 'umbra/labeledfield'

def create_footer_window h = 2 , w = FFI::NCurses.COLS, t = FFI::NCurses.LINES-2, l = 0
  ewin = Window.new(h, w , t, l)
end
def _alert str 
  win = create_footer_window
  #FFI::NCurses.init_pair(12,  COLOR_WHITE, FFI::NCurses::RED)
  cp = create_color_pair(COLOR_RED, COLOR_WHITE)
  win.wbkgd(FFI::NCurses.COLOR_PAIR(cp)) # white on red, defined here
  win.printstring(0,1, str)
  win.wrefresh
  win.getkey
  win.destroy
end
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
  include Umbra
  init_curses
  startup
  #FFI::NCurses.init_pair(12,  COLOR_WHITE, FFI::NCurses::RED)
  win = Window.new
  statusline(win, " "*(win.width-0), 0)
  statusline(win, "Press C-q to quit #{win.height}:#{win.width}", 20)
  title = Label.new( :text => "Demo of LabeledFields", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1, 
                    :justify => :center, :color_pair => CP_BLACK)

  form = Form.new win
  form.add_widget title
  labels = ["Name:", "Age:", "Address:","Mobile No.:", "Email Id:","Hobbies:"]
  labs = []
  row = 3
  col = 5
=begin
  labels.each_with_index {|lab, ix| 
    w = Label.new( :text => lab, :row => row, :col => col , :width => 20)
    labs << w
    row += 2
    w.color_pair = CP_WHITE
    w.justify = :right
    w.attr = FFI::NCurses::A_BOLD
    form.add_widget w
  }
=end
  labels = ["Name:", "Age:", "Address:","Mobile No.:", "Email Id:","Hobbies:"]
  names = ["name", "age", "address","mobile", "email","hobbies"]
 
  row = 3
  col = 30
  fhash = {}
  names.each_with_index {|lab, ix| 
    w = LabeledField.new( :name => lab, :row => row, :col => col , :width => 50, label: labels[ix],
                         :label_highlight_attr => BOLD
                        )
    fhash[lab] = w
    row += 2
    w.color_pair = CP_CYAN
    w.attr = FFI::NCurses::A_REVERSE
    w.highlight_color_pair = CP_YELLOW
    w.highlight_attr = REVERSE
    w.null_allowed = true
    form.add_widget w
  }
  message_label = Label.new({text: "Message comes here C-q to quit",
                             :name=>"message_label",:row => win.height-2, :col => 2, :width => 60,
                             :height => 2, :color_pair => CP_MAGENTA})
  form.add_widget message_label
  #fhash["mobile"].type = :integer
  fhash["mobile"].chars_allowed = /[\d\-]/
  fhash["mobile"].maxlen = 10
  fhash["mobile"].mnemonic = "m"
  fhash["name"].mnemonic = "n"
  fhash["age"].mnemonic = "a"
  fhash["address"].mnemonic = "d"
  fhash["mobile"].bind_event(:CHANGE) do |f|
    message_label.text = "#{f.getvalue.size()} chars entered"
    statusline(win, "#{f.getvalue.size()} chars entered")
    message_label.repaint_required
  end
  fhash["email"].chars_allowed = /[\w\+\.\@]/
  fhash["email"].valid_regex = /\w+\@\w+\.\w+/
  fhash["age"].valid_range = (18..100)
  fhash["age"].type = :integer
  fhash["hobbies"].maxlen = 100
  form.pack
  form.select_first_field
  win.wrefresh

  y = x = 1
  while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
    begin
      form.handle_key ch
    rescue => e
      _alert(e.to_s)
      $log.error e
      $log.error e.backtrace.join("\n")
      e = nil
    end
    win.wrefresh
  end

rescue => e
  win.destroy if win
  FFI::NCurses.endwin
  puts "printing inside rescue"
  puts e
  puts e.backtrace.join("\n")
  e = nil
ensure
  win.destroy if win
  FFI::NCurses.endwin
  if e
    puts "printing inside ensure"
    puts e 
    puts e.backtrace.join("\n")
  end
end
