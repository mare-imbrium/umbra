#!/usr/bin/env ruby
# example showing listbox
# 2018-03-19 -
require 'umbra'
require 'umbra/label'
require 'umbra/listbox'
require 'umbra/box'
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
def statusline win, str, column = 1
  # LINES-2 prints on second last line so that box can be seen
  win.printstring( FFI::NCurses.LINES-2, column, str, 6, REVERSE)
end
begin
  include Umbra
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
    box = Box.new row: 4, col: 2, width: 80, height: 20
    lb = Listbox.new list: alist
    box.fill lb
    win.printstring(box.row+1,0,"XX")
    win.printstring(box.row+1,box.col+box.width,"XX")
    win.printstring(box.row+box.height,1,"This prints below the listbox")
    brow = box.row+box.height+3
    tb = ToggleButton.new onvalue: "Toggle", offvalue: "No Toggle", row: brow, col: 10, value: true
    ab = Button.new text: "Processes" , row: brow, col: 30
    logb = Button.new text: "LogFile" , row: brow, col: 50

    tb.command do
      if tb.value
        # we no longer have border in listboxes or textboxes
        #lb.border true
        box.title = "Toggled"
      else
        #lb.border false
        box.title = "Untoggled"
      end
    end
    # bind the most common event for a listbox which is ENTER_ROW
    lb.command do |ix|
      statusline(win, "Sitting on offset #{lb.current_index}, #{ix.first} ")
    end
    ab.command do 
      lb.color_pair = create_color_pair(COLOR_BLACK, COLOR_CYAN)
      #lb.attr = REVERSE
      lb.list = %x{ ps aux }.split("\n")
      box.title = "Processes"
      box.repaint_required = true
    end
    logb.command do
      lb.list=[]
      lb.repaint_required=true
      box.title = "Log File"
      box.repaint_required = true
      # We require a timeout in getch for this to update
      # without thread process hangs and no update happens
      t = Thread.new do
        IO.popen("tail -f v.log") do |output|
          ctr = 0
          while line = output.gets do
            lb.list << line.chomp
            lb.goto_end
            lb.repaint_required=true
            form.repaint
            ctr += 1
            if ctr > 100
              sleep(1)
              ctr = 0
            end
          end
        end
      end
    end
    # bind to another event of listbox
    lb.bind_event(:LEAVE_ROW) { |ix| statusline(win, "LEFT ROW #{ix.first}", 50) }
    lb.bind_event(:SELECT_ROW) { |w| alert("You selected row #{w.selected_index || "none"} ") }
    form.add_widget box, lb
    form.add_widget tb
    form.add_widget ab
    form.add_widget logb
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
