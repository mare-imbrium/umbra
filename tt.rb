#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: tt.rb
#  Description: a quick small directory lister aimed at being simple and fast.
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-09 
#      License: MIT
#  Last update: 2018-03-13 12:31
# ----------------------------------------------------------------------------- #
#  tt.rb  Copyright (C) 2012-2018 j kepler
#  == TODO
# [x] open files on RIGHT arrow in view (?)
# [ ] pressing p should open PAGER, e EDITOR, m MOST, v - view
# [ ] on zip file show contents in pager. x to extract.
# [ ] when going up a directory keep cursor on the directory we came from XXX
# [ ] space bar to page down. also page up on c-n c-p top bottom
# [x] hide dot files 
# [ ] reveal dot files on toggle TODO
# [ ] long file names not getting cleared FIXME
# [ ] allow entry of command and page output or show in PAGER
# [x] pressing ENTER should invoke EDITOR
#  ----------
#  == CHANGELOG
#
#
#  --------
#
require './window.rb'
require './menu.rb'

def create_footer_window h = 2 , w = FFI::NCurses.COLS, t = FFI::NCurses.LINES-2, l = 0
  ewin = Window.new(h, w , t, l)
end
def shell_out command
      FFI::NCurses.endwin
      ret = system command
      FFI::NCurses.refresh
end

def file_edit win, fp 
  #$log.debug " edit #{fp}"
  editor = ENV['EDITOR'] || 'vi'
  vimp = %x[which #{editor}].chomp
  shell_out "#{vimp} #{fp}"
end
def file_open win, fp 
  unless File.exists? fp
    pwd = %x[pwd]
    #alert "No such file. My pwd is #{pwd} "
    alert win, "No such file. My pwd is #{pwd} "
    return
  end
  ft=%x[file #{fp}]
  if ft.index("text")
    file_edit win, fp
  elsif ft.index(/zip/i)
    shell_out "tar tvf #{fp} | less"
  elsif ft.index(/directory/i)
    shell_out "ls -lh  #{fp} | less"
  else
    alert "#{fp} is not text, not opening (#{ft}) "
  end
end
def file_page win, fp 
  unless File.exists? fp
    pwd = %x[pwd]
    alert "No such file. My pwd is #{pwd} "
    return
  end
  ft=%x[file #{fp}]
  if ft.index("text")
    pager = ENV['PAGER'] || 'less'
    vimp = %x[which #{pager}].chomp
    shell_out "#{vimp} #{fp}"
  elsif ft.index(/zip/i)
    shell_out "tar tvf #{fp} | less"
  elsif ft.index(/directory/i)
    shell_out "ls -lh  #{fp} | less"
  else
    alert "#{fp} is not text, not paging "
    #use_on_file "als", fp # only zip or archive
  end
end
def get_files
  #files = Dir.glob("*")
  $sorto = "on"
  $hidden = nil
  files = `zsh -c 'print -rl -- *(#{$sorto}#{$hidden}M)'`.split("\n")
end
# a quick simple list with highlight row, and scrolling
# clear the rest of the rows DONE 2018-03-09 - 
# mark directories in color or / DONE
# entire window should have same color as bkgd - DONE
#
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
        #ff = "#{mark} #{f}/"
        # 2018-03-12 - removed slash at end since zsh puts it there
        ff = "#{mark} #{f}"
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
  def OLDalert win, str
    statusline win, str
    win.getkey
  end
  def alert str 
    win = create_footer_window
    # 10 is too much BLACK on CYAN
    win.wbkgd(FFI::NCurses.COLOR_PAIR(12))
    win.printstring(0,1, str)
    win.wrefresh
    win.getkey
    win.destroy
  end

begin
  init_curses
  txt = "Press cursor keys to move window"
  win = Window.new
  $ht = win.height
  $wid = win.width
  $pagecols = $ht / 2
  $spacecols = $ht
  #win.printstr txt
  win.printstr("Press Ctrl-Q to quit #{win.height}:#{win.width}", win.height-1, 20)

  path = File.expand_path("./")
  win.printstring(0,0, "DIR: #{path}                 ",0)
  files = get_files
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
        files = get_files
        current = 0
        #FFI::NCurses.wclrtobot(win.getwin)
        win.wclrtobot
      elsif File.readable? fullp
        file_page win, fullp
        win.wrefresh
        # open file
      end
      x += 1
    when FFI::NCurses::KEY_LEFT
      # go back higher level
      oldpath = path
      Dir.chdir("..")
      path = Dir.pwd
      win.printstring(0,0, "DIR: #{path}                 ",0)
      files = get_files
      # when going up, keep focus on the dir we came from
      current = files.index(File.basename(oldpath) + "/")
      current = 0 if current.nil? or current == -1
      win.wclrtobot
      x -= 1
    when FFI::NCurses::KEY_RETURN
      # if directory then open it
      fullp = path + "/" + files[current]
      if File.directory? fullp
        Dir.chdir(files[current])
        path = Dir.pwd
        win.printstring(0,0, "DIR: #{path}                 ",0)
        files = get_files
        #files = Dir.entries("./")
        #files.delete(".")
        #files.delete("..")
        current = 0
        win.wclrtobot
      elsif File.readable? fullp
        # open file
        file_open win, fullp
        win.wrefresh
      end
    when FFI::NCurses::KEY_UP
      current -=1
    when FFI::NCurses::KEY_DOWN
      current +=1
    when FFI::NCurses::KEY_CTRL_N
      current += $pagecols
    when 32
      current += $spacecols
    when FFI::NCurses::KEY_BACKSPACE, 127
      current -= $spacecols
    when FFI::NCurses::KEY_CTRL_A
      list = ["x this", "y that","z other","a foo", "b bar"]
      list = { "x" => "this", "y" => "that", "z" => "the other", "a" => "another one", "b" => "yet another" }
      m = Menu.new "A menu", list
      key = m.getkey
      win.wrefresh # otherwise menu popup remains till next key press.
      alert("Received #{key} from menu")
    else
      alert("key #{ch} not known")
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
