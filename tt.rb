#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: tt.rb
#  Description: a quick small directory lister aimed at being simple fast with minimal
#       features, and mostly for viewing files quickly through PAGER
#       Author: j kepler  http://github.com/mare-imbrium/
#         Date: 2018-03-09 
#      License: MIT
#  Last update: 2018-03-16 23:17
# ----------------------------------------------------------------------------- #
#  tt.rb  Copyright (C) 2012-2018 j kepler
#  == TODO
#  [ ] make a help screen on ?
#  [ ] move to lyra or some gem and publish
#  [ ] pop directories
#  [ ] go back to start directory
#  [ ] go to given directory
# [x] open files on RIGHT arrow in view (?)
# [ ] in a long listing, how to get to a file name. first char or pattern TODO
# [ ] pressing p should open PAGER, e EDITOR, m MOST, v - view
# [x] on zip file show contents in pager. x to extract.
# [x] when going up a directory keep cursor on the directory we came from 
# [x] space bar to page down. also page up on c-n c-p top bottom
# [x] hide dot files 
# [x] reveal dot files on toggle 
# [x] long listing files on toggle 
# [x] long file names not getting cleared 
# [ ] allow entry of command and page output or show in PAGER
# [x] pressing ENTER should invoke EDITOR
# [x] scrolling up behavior not correct. we should scroll up from first row not last. 
#     see vifm for correct way. mc has different behavior
#  ----------
#  == CHANGELOG
#
#
#  --------
#
require './window.rb'
require './menu.rb'

$sorto = "on"
$hidden = nil
$long_listing = false
$patt = nil
_LINES = FFI::NCurses.LINES-1
def create_footer_window h = 2 , w = FFI::NCurses.COLS, t = FFI::NCurses.LINES-2, l = 0
  ewin = Window.new(h, w , t, l)
end
def create_input_window h = 1 , w = FFI::NCurses.COLS, t = FFI::NCurses.LINES-1, l = 0
  ewin = Window.new(h, w , t, l)
end
# accepts user input in current window
# and returns characters after RETURN pressed
def getchars win, max=20
  str = ""
  pos = 0
  filler = " "*max
  y, x = win.getyx()
  pointer = win.pointer
  while (ch = win.getkey) != FFI::NCurses::KEY_RETURN
    #str << ch.chr
    if ch > 27 and ch < 127
      str.insert(pos, ch.chr)
      pos += 1
      #FFI::NCurses.waddstr(win.pointer, ch.chr)
    end
    case ch
    when FFI::NCurses::KEY_LEFT 
      pos -= 1
      pos = 0 if pos < 0
    when FFI::NCurses::KEY_RIGHT
      pos += 1
      pos = str.size if pos >= str.size
    when 127
      pos -= 1 if pos > 0
      str.slice!(pos,1) if pos >= 0 # no backspace if on first pos
    when 27, FFI::NCurses::KEY_CTRL_C
      return nil
    end
    FFI::NCurses.wmove(pointer, y,x)
    FFI::NCurses.waddstr(pointer, filler)
    FFI::NCurses.wmove(pointer, y,x)
    FFI::NCurses.waddstr(pointer, str)
    FFI::NCurses.wmove(pointer, y,pos+1) # set cursor to correct position
    break if str.size >= max
  end
  str
end
# runs given command and returns.
# Does not wait, so command should be like an editor or be paged to less.
def shell_out command
      FFI::NCurses.endwin
      ret = system command
      FFI::NCurses.refresh
end

## code related to long listing of files
GIGA_SIZE = 1073741824.0
MEGA_SIZE = 1048576.0
KILO_SIZE = 1024.0

# Return the file size with a readable style.
def readable_file_size(size, precision)
  case
    #when size == 1 : "1 B"
  when size < KILO_SIZE then "%d B" % size
  when size < MEGA_SIZE then "%.#{precision}f K" % (size / KILO_SIZE)
  when size < GIGA_SIZE then "%.#{precision}f M" % (size / MEGA_SIZE)
  else "%.#{precision}f G" % (size / GIGA_SIZE)
  end
end
## format date for file given stat
def date_format t
  t.strftime "%Y/%m/%d"
end
# clears window but leaves top line
def clearwin(win)
      win.wmove(1,0)
      win.wclrtobot
end
## 
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
  files = `zsh -c 'print -rl -- *(#{$sorto}#{$hidden}M)'`.split("\n")
  if $patt
    files = files.grep(/#{$patt}/)
  end
  return files
end
# a quick simple list with highlight row, and scrolling
# 
# mark directories in color 
# @return start row
  def listing win, path, files, cur=0, pstart
    curpos = 1
    width = win.width-1
    y = x = 1
    ht = win.height-2
    #st = 0
    st = pstart           # previous start
    pend = pstart + ht -1 # previous end
    if cur > pend
      st = (cur -ht) +1
    elsif cur < pstart
      st = cur
    end
    hl = cur
    #if cur >= ht
      #st = (cur - ht ) +1
      #hl = cur
      ## we need to scroll the rows
    #end
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
        curpos = ctr
      else
        attr = FFI::NCurses::A_NORMAL
      end
      fullp = path + "/" + f

      if $long_listing
        begin
          unless File.exist? f
            last = f[-1]
            if last == " " || last == "@" || last == '*'
              stat = File.stat(f.chop)
            end
          else
            stat = File.stat(f)
          end
          f = "%10s  %s  %s" % [readable_file_size(stat.size,1), date_format(stat.mtime), f]
        rescue Exception => e
          f = "%10s  %s  %s" % ["?", "??????????", f]
        end
      end
      if File.directory? fullp
        #ff = "#{mark} #{f}/"
        # 2018-03-12 - removed slash at end since zsh puts it there
        ff = "#{mark} #{f}"
        colr = 4 # blue on background color_pair COLOR_PAIR
        attr = attr | FFI::NCurses::A_BOLD
      else
        ff = "#{mark} #{f}"
      end
      win.printstring(ctr, x, filler, colr )
      win.printstring(ctr, x, ff, colr, attr)
      break if ctr >= ht
    }
    #curpos = cur + 1
    #if curpos > ht
      #curpos = ht 
    #end
    #statusline(win, "#{cur+1}/#{files.size} #{files[cur]}. cur = #{cur}, pos:#{curpos},ht = #{ht} , hl #{hl}")
    statusline(win, "#{cur+1}/#{files.size} #{files[cur]}. (#{$sorto})                                ")
    win.wmove( curpos , 0) # +1 depends on offset of ctr 
    win.wrefresh
    return st
  end
  def statusline win, str
    win.printstring(win.height-1, 2, str, 1) # white on default
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
  def main_menu
    h = { :s => :sort_menu, :M => :newdir, "%" => :newfile }
    m = Menu.new "Main Menu", h
    ch = m.getkey

    binding = h[ch]
    binding = h[ch.to_sym] unless binding
    if binding
      if respond_to?(binding, true)
        send(binding)
      end
    end
    return ch, binding
  end

  def sort_menu
    lo = nil
    h = { :n => :newest, :a => :accessed, :o => :oldest, 
          :l => :largest, :s => :smallest , :m => :name , :r => :rname, :d => :dirs, :c => :clear }
      m = Menu.new "Sort Menu", h
      ch = m.getkey
      menu_text = h[ch.to_sym]
      case menu_text
      when :newest
        lo="om"
      when :accessed
        lo="oa"
      when :oldest
        lo="Om"
      when :largest
        lo="OL"
      when :smallest
        lo="oL"
      when :name
        lo="on"
      when :rname
        lo="On"
      when :dirs
        lo="/"
      when :clear
        lo=""
      end
      ## This needs to persist and be a part of all listings, put in change_dir.
      $sorto = lo
      #$files = `zsh -c 'print -rl -- *(#{lo}#{$hidden}M)'`.split("\n") if lo
      #$title = nil
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
  prevstart = listing(win, path, files, current, 0)

  ch = 0
  xx = 1
  yy = 1
  y = x = 1
  while (ch = win.getkey) != 113
    #y, x = win.getbegyx(pointer)
    old_y, old_x = y, x
    case ch
    when FFI::NCurses::KEY_RIGHT
      # if directory then open it
      fullp = path + "/" + files[current]
      if File.directory? fullp
        Dir.chdir(files[current])
        $patt = nil
        path = Dir.pwd
        win.printstring(0,0, "DIR: #{path}                 ",0)
        files = get_files
        current = 0
        #FFI::NCurses.wclrtobot(pointer)
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
      $patt = nil
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
        $patt = nil
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
    when FFI::NCurses::KEY_CTRL_P
      current -= $pagecols
    when 32
      current += $spacecols
    when FFI::NCurses::KEY_BACKSPACE, 127
      current -= $spacecols
    when FFI::NCurses::KEY_CTRL_X
    when ?=.getbyte(0)
      #list = ["x this", "y that","z other","a foo", "b bar"]
      list = { "h" => "hidden files toggle", "l" => "long listing toggle", "z" => "the other", "a" => "another one", "b" => "yet another" }
      m = Menu.new "Toggle Options", list
      key = m.getkey
      win.wrefresh # otherwise menu popup remains till next key press.
      case key
      when 'h'
        $hidden = $hidden ? nil : "D"
        files = get_files
        clearwin(win)
      when 'l'
        $long_listing = !$long_listing 
        clearwin(win)
      end
    when ?/.getbyte(0)
      # search grep
      # this is writing over the last line of the listing
      ewin = create_input_window
      ewin.printstr("/", 0, 0)
      #win.wmove(1, _LINES-1)
      str = getchars(ewin, 10)
      ewin.destroy
      #alert "Got #{str}"
      $patt = str #if str
      files = get_files
      clearwin(win)
    when ?`.getbyte(0)
      main_menu
      files = get_files
      clearwin(win)
    else
      alert("key #{ch} not known")
    end
    #win.printstr("Pressed #{ch} on #{files[current]}    ", 0, 70)
    current = 0 if current < 0
    current = files.size-1 if current >= files.size
    # listing does not refresh files, so if files has changed, you need to refresh
    prevstart = listing(win, path, files, current, prevstart)
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
