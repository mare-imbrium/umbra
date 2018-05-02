#!/usr/bin/env ruby
# example showing only labels and fields a window
# 2018-03-10 
require 'umbra'
require 'umbra/label'
require 'umbra/button'
require 'umbra/labeledfield'
require 'umbra/messagebox'

def create_footer_window h = 2 , w = FFI::NCurses.COLS, t = FFI::NCurses.LINES-2, l = 0
  ewin = Window.new(h, w , t, l)
end
def old_alert str 
  win = create_footer_window
  #FFI::NCurses.init_pair(12,  COLOR_WHITE, FFI::NCurses::RED)
  cp = create_color_pair(COLOR_RED, COLOR_WHITE)
  win.wbkgd(FFI::NCurses.COLOR_PAIR(cp)) # white on red, defined here
  win.printstring(0,1, str)
  win.wrefresh
  win.getkey
  win.destroy
end
def _alert array, title="Alert"
  mb = MessageBox.new title: title, buttons: "Ok"  do
    text array
  end
  mb.run
end
def _alert_message str, title="Alert" 
  mb = MessageBox.new title: title, buttons: "Okay" do
    message str
  end
  mb.run
end
def _alert_fields str 
  #mb = MessageBox.new height: 20, width: 60, row: 5, col: 5, title: "Enter yor name" do
  mb = MessageBox.new title: "Testing Messageboxes", width: 80 do
    add Label.new text: "Name"
    add Field.new name:"name", default: "Rahul", width: 25, color_pair: CP_CYAN, attr: REVERSE
    add LabeledField.new label:"Age:", name:"age", text:"25", col: 15, color_pair: CP_CYAN, attr: REVERSE
    # unfortunately this exceeds since width only takes field into account not label
    add LabeledField.new label:"Address:", name:"address", width:50 , maxlen: 70, col: 15, color_pair: CP_CYAN, attr: REVERSE
  end
  mb.run
end
def startup
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Date.today
    $log.info "MessageBox demo #{$0} started on #{today}"
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
  title = Label.new( :text => "Demo of MessageBox", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1, 
                    :justify => :center, :color_pair => CP_BLACK)

  form = Form.new win
  form.add_widget title

  b1 = Button.new text: "String", row: 10, col: 10
  b2 = Button.new text: "Array", row: 10, col: 30
  b3 = Button.new text: "Fields", row: 10, col: 50
  b4 = Button.new text: "Confirm", row: 10, col: 70
  message_label = Label.new({text: "Message comes here C-q to quit",
                             :name=>"message_label",:row => win.height-2, :col => 2, :width => 60,
                             :height => 2, :color_pair => CP_MAGENTA})
  b1.command do
    _alert_message "This is an alert with a string"
  end
  b2.command do
    array = File.read($0).split("\n")
    _alert(array, $0)
  end
  b3.command do
    _alert_fields "dummy"
  end
  b4.command do
    ret = confirm "Do you wish to go?"
    message_label.text = "You selected #{ret}"
  end
  form.add_widget message_label, b1, b2, b3, b4
  form.pack
  form.select_first_field
  win.wrefresh

  y = x = 1
  while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
    begin
      form.handle_key ch
    rescue => e
      #_alert(e.to_s.strip + ".")

      _alert(["Error in Messagebox: #{e} ", *e.backtrace], "Exception")
      #_alert(e.backtrace)
      $log.error e
      $log.error e.backtrace.join("\n")
      e = nil
    end
    win.wrefresh
  end

rescue => e
  win.destroy if win
  FFI::NCurses.endwin
      $log.error e
      $log.error e.backtrace.join("\n")
  puts "printing inside rescue"
  puts e
  puts e.backtrace.join("\n")
  e = nil
ensure
  win.destroy if win
  FFI::NCurses.endwin
  if e
      $log.error e
      $log.error e.backtrace.join("\n")
    puts "printing inside ensure"
    puts e 
    puts e.backtrace.join("\n")
  end
end
