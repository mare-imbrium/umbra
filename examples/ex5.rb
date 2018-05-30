#!/usr/bin/env ruby
# example showing Textbox
# 2018-03-19 -
require 'umbra'
require 'umbra/label'
require 'umbra/box'
require 'umbra/textbox'
require 'umbra/togglebutton'

def startup
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Time.now.to_s
    $log.info "Textbox demo #{$0} started on #{today}"
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
  str = " Demo of Textbox "
  win.title str
=begin
  alist = ["one item"*4, "another item"*10, "yet another item"*15]
  #alist = []
  (1..50).each do |i|
    alist << "#{i} entry"
  end
=end
  filename = "./notes"

  catch(:close) do
    form = Form.new win
    win.printstring(3,1,"Just testing that Textbox is correctly positioned")
    box = Box.new row: 4, col: 2, width: 50, height: 20
    lb = Textbox.new file_name: filename
    box.fill lb
    box.title = filename
    win.printstring(box.row+1,0,"XX")
    win.printstring(box.row+1,box.col+box.width,"XX")
    win.printstring(box.row+box.height,1,"This prints below the Textbox")
    brow = box.row+box.height+3
    tb = ToggleButton.new onvalue: "Left", offvalue: "Center", row: brow, col: 10, value: true

    tb.command do
      if tb.value
        box.justify = :center
      else
        box.justify = :left
      end
      #box.repaint_required  = true
    end
    #lb.bind_event(:CURSOR_MOVE) {|arr|
    lb.bind_event(:CURSOR_MOVE) {|lb|
      col_offset , current_index, curpos,  pcol = lb.col_offset, lb.current_index, lb.curpos, lb.panned_cols
      blen = lb.current_row().size
      statusline(win, "offset: #{col_offset} , curpos: #{curpos} , currind: #{current_index} , pcol #{pcol}, len:#{blen}.....", 20)
    }
    form.add_widget box, lb
    form.add_widget tb
    form.pack
    form.repaint
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
