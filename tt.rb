#!/usr/bin/env ruby
#
require './window.rb'

# a quick simple list with highlight row, and scrolling
# and it won't clear previous rows, if next listing is shorter. TODO
# We should use the pad of canis. TODO maybe
# clear the rest of the rows DONE 2018-03-09 - 
# mark directories in color or / TODO
# entire window should have same color as bkgd
  def listing win, path, files, cur=0
    width = 50
    y = x = 1
    ht = win.height-2
    st = 0
    hl = cur
    if cur >= ht
      st = (cur - ht ) +1
      hl = cur
      # we need to scroll the rows
    end
    y = 0
    ctr = 0
    filler = " "*width
    files.each_with_index {|f, y| 
      next if y < st
      colr = 1 # white on bg -1
      ctr += 1
      mark = " "
      if y == hl
        attr = FFI::NCurses::A_REVERSE
        mark = ">"
      else
        attr = FFI::NCurses::A_NORMAL
      end
      fullp = path + "/" + f
      if File.directory? fullp
        ff = "#{mark} #{f}/"
        colr = 4 # blue on background
        attr = attr | FFI::NCurses::A_BOLD
      else
        ff = "#{mark} #{f}"
      end
      win.printstring(ctr, x, filler, colr )
      win.printstring(ctr, x, ff, colr, attr)
      break if ctr >= ht
    }
    statusline(win, "#{cur+1}/#{files.size} #{files[cur]}. cur, ht = #{ht} , hl #{hl}")
    win.wrefresh
    #return cur
  end
  def statusline win, str
    win.printstring(win.height-1, 2, str, 2)
  end

begin
  init_curses
  txt = "Press cursor keys to move window"
  win = Window.new
  #win.printstr txt
  win.printstr("Press Ctrl-Q to quit #{win.height}:#{win.width}", win.height-1, 20)

  path = File.expand_path("./")
  win.printstring(0,0, "DIR: #{path}                 ",0)
  files = Dir.entries("./")
  files.delete(".")
  files.delete("..")
  current = 0
  listing(win, path, files, current)

  ch = 0
  xx = 1
  yy = 1
  y = x = 1
  while (ch = win.getkey) != 113
    #y, x = win.getbegyx(win.getwin)
    old_y, old_x = y, x
    case ch
    when FFI::NCurses::KEY_RIGHT
      # if directory then open it
      fullp = path + "/" + files[current]
      if File.directory? fullp
        Dir.chdir(files[current])
        path = Dir.pwd
        win.printstring(0,0, "DIR: #{path}                 ",0)
        files = Dir.entries("./")
        files.delete(".")
        files.delete("..")
        current = 0
        #FFI::NCurses.wclrtobot(win.getwin)
        win.wclrtobot
      end
      x += 1
    when FFI::NCurses::KEY_LEFT
      # go back higher level
      Dir.chdir("..")
      path = Dir.pwd
      win.printstring(0,0, "DIR: #{path}                 ",0)
      files = Dir.entries("./")
      files.delete(".")
      files.delete("..")
      current = 0
      win.wclrtobot

      x -= 1
    when FFI::NCurses::KEY_UP
      current -=1
    when FFI::NCurses::KEY_DOWN
      current +=1
    end
    #FIXME after scrolling, pointer is showing wrong file here
    win.printstr("Pressed #{ch} on #{files[current]}    ", 0, 70)
    current = 0 if current < 0
    current = files.size-1 if current >= files.size
    win.printstr(ch.to_s + ":" + current.to_s, 0, 40)
    listing(win, path, files, current)
    win.wrefresh
  end

rescue Object => e
  @window.destroy if @window
  FFI::NCurses.endwin
  puts e
  puts e.backtrace.join("\n")
ensure
  @window.destroy if @window
  FFI::NCurses.endwin
  puts 
end
