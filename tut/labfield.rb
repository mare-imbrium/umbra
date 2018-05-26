#!/usr/bin/env ruby
# example showing labeledfield
#  2018-05-26 
require 'umbra'
require 'umbra/label'
require 'umbra/labeledfield'

begin
  include Umbra
  init_curses
  win = Window.new
  title = Label.new( :text => "Demo of LabeledFields", :row => 0, :col => 0 , :width => -1, 
                    :justify => :center, :color_pair => CP_BLACK)

  form = Form.new win
  form.add_widget title
  labels = ["Name:", "Age:", "Address:","Mobile No.:", "Email Id:","Hobbies:"]
  names = ["name", "age", "address","mobile", "email","hobbies"]
 
  row = 3
  col = 30
  names.each_with_index {|lab, ix| 
    w = LabeledField.new( :name => lab, :row => row, :col => col , :width => 50, label: labels[ix],
                         :label_highlight_attr => BOLD
                        )
    row += 2
    w.color_pair = CP_CYAN
    w.attr = FFI::NCurses::A_REVERSE
    w.highlight_color_pair = CP_YELLOW
    w.highlight_attr = REVERSE
    w.null_allowed = true
    form.add_widget w
  }
  message_label = Label.new({text: "Message comes here C-q to quit",
                             :name=>"message_label",:row => -2, :col => 2, :width => 60,
                             :color_pair => CP_MAGENTA})
  form.add_widget message_label
  form.pack
  form.select_first_field
  win.wrefresh

  y = x = 1
  while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
    if ch == -1
      message_label.text = Time.now
      form.repaint
      next
    end
    begin
      form.handle_key ch
    rescue => e
      alert(e.to_s)
    end
    win.wrefresh
  end

rescue => e
  win.destroy if win
  FFI::NCurses.endwin
ensure
  win.destroy if win
  FFI::NCurses.endwin
end
