#!/usr/bin/env ruby
# tutorial example with a label and a field
# 2018-05-25 - 14:00 
require 'umbra'
require 'umbra/label'
require 'umbra/field'

begin
  include Umbra
  init_curses
  win = Window.new
  ## Create a label on top, spanning the second column
  title = Label.new( :text => "Demo of Fields", :row => 1, :col => 1 , :width => FFI::NCurses.COLS-2, 
                    :justify => :center, :color_pair => CP_BLACK)

  form = Form.new win
  form.add_widget title     ## register label with form
  row = 3
  col = 5
  ## create another label
  w = Label.new( :text => "Name:", :row => row, :col => col , :width => 20)
  w.color_pair = CP_WHITE
  w.justify = :right
  w.attr = FFI::NCurses::A_BOLD
  form.add_widget w

  row = 3
  col = 30
  ## create a field
    w = Field.new( :name => "name", :row => row, :col => col , :width => 50)
    w.color_pair = CP_CYAN
    w.attr = FFI::NCurses::A_REVERSE
    w.highlight_color_pair = CP_YELLOW
    w.highlight_attr = REVERSE
    w.null_allowed = true
    w.values = %w{ruby perl python java awk sed rust lua}
    w1 = Field.new( :name => "address", :row => row+1, :col => col , :width => 50)
    w1.color_pair = w.color_pair
    w1.attr = w.attr
    form.add_widget w, w1


    ## Create a label and position at the bottom row
  message_label = Label.new({text: "Message comes here C-q to quit",
                             :name=>"message_label",:row => win.height-2, :col => 2, :width => -2,
                             :color_pair => CP_MAGENTA})
  form.add_widget message_label


  form.pack
  form.select_first_field
  win.wrefresh

  while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
    next if ch == -1
    begin
      form.handle_key ch
    rescue => e
      alert e.to_s
    end
    win.wrefresh
  end

rescue => e
  win.destroy if win
  FFI::NCurses.endwin
  puts e.to_s
  puts e.backtrace.join("\n")
ensure
  win.destroy if win
  FFI::NCurses.endwin
end
