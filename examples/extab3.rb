#!/usr/bin/env ruby
# ----------------------------------------------------------------------------- #
#         File: extab3.rb
#  Description: Example of using a Table with an sqlite3 resultset.
#       Author: j kepler  http://github.com/mare-imbrium/umbra/
#         Date: 2018-05-11
#      License: MIT
#  Last update: 2018-05-15 18:33
# ----------------------------------------------------------------------------- #
#  extab3.rb  Copyright (C) 2018 j kepler
require 'umbra'
require 'umbra/label'
require 'umbra/tabular'
require 'umbra/box'
require 'umbra/table'
require 'sqlite3'

def startup
  require 'logger'
  require 'date'

    path = File.join(ENV["LOGDIR"] || "./" ,"v.log")
    file   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    $log = Logger.new(path)
    $log.level = Logger::DEBUG
    today = Date.today
    $log.info "Started demo table #{$0} on #{today}"
    path = File.dirname(__FILE__)
    $log.info "PATH: #{path}"
    FFI::NCurses.init_pair(10,  FFI::NCurses::BLACK,   FFI::NCurses::GREEN) # statusline
    @file = "#{path}/data/tennis.sqlite"
    @db = SQLite3::Database.new(@file)
    @tablename = "matches"
end
def ORIGstatusline win, str, col = 0
  win.printstring( FFI::NCurses.LINES-1, col, str, 10)
end
def statusline win, str, column = 1
  # LINES-2 prints on second last line so that box can be seen
  win.printstring( FFI::NCurses.LINES-1, 0, " "*(win.width), 6, REVERSE)
  # printing fields in two alternating colors so easier to see
  str.split("|").each_with_index {|s,ix|
    _color = 6
    _color = 5 if ix%2==0
    win.printstring( FFI::NCurses.LINES-1, column, s, _color, REVERSE)
    column += s.length+1
  }
end   # }}}
def get_data db, sql # {{{
  $log.debug "SQL: #{sql} "
  columns, *rows = db.execute2(sql)
  content = rows
  return nil if content.nil? or content[0].nil?
  datatypes = content[0].types #if @datatypes.nil?
  return content, columns, datatypes
end # }}}
def view_details(table)
  id = table.current_id

  res = %x{ sqlite3 #{@file} -line "select * from #{@tablename} where rowid = '#{id}'"}
  if res and !res.empty?
    res = res.split("\n")
    view res
  else
    alert("No row for #{id} in #{@tablename}")
  end
end
def get_full_row_as_hash(table)
  id = table.current_id
  data, columns, datatypes = get_data(@db, "select * from #{@tablename} where rowid = '#{id}'")
  hash = columns.zip(data.first).to_h
  #$log.debug "  HASH == #{hash}"
  return hash
end
def filter_popup lb # {{{
  ## present user with a popup allowing him to select range of rating title, range of year, status etc
  ##  for querying.
  #rowdata = get_data(@db, "select title, actors, director, imdbrating, language, genre , metascore, imdbvotes from #{@tablename} WHERE rowid = #{id}")
  data = []
  _columns = ["tourney_name", "winner_name", "loser_name", "surface", "Year >", "Year <", "round", "level", "best_of"]
  _columns.each {|c| data << "" }
  _datatypes = ["text","text","text","char(10)","char(4)","char(4)","char(5)", "char(1)", "char(1)"]
  ret, array = generic_edit "Filter", _columns, data, _datatypes
  if ret == 0
    # okay pressed
    ## query database on values entered TODO
    _filter_table(lb, _columns, array)
  end
end # }}}
def _filter_table(lb, columns, fields)
  cols = []
  bind_vars = []
  sql = "#{@query}"
  fields.each_with_index { |f, ix|
    next if f.text == ""
    c = columns[ix].downcase
    if c == "round"
      cols << " round = ? "
      bind_vars << "#{f.text}"
    elsif c == "year >"
      cols << " tourney_date >= ?  "
      bind_vars << "#{f.text}"
    elsif c == "year <"
      cols << " tourney_date <= ? "
      bind_vars << "#{f.text}"
    elsif c == "level"
      cols << " tourney_level = ? "
      bind_vars << "#{f.text}"
    elsif c == "best_of"
      cols << " best_of =  ? "
      bind_vars << "#{f.text}"
    else
      cols << columns[ix] + " LIKE ? "
      bind_vars << "%#{f.text}%"
    end
  }
  if !cols.empty?
    sql +=  " WHERE " + cols.join(" AND ")
  end
  $log.debug "  SQL: #{sql} "
  $log.debug "  ibv:  #{bind_vars.join ', '} "
  alist = @db.execute( sql, bind_vars)
  if alist #and !alist.empty?
    #lb.list = alist   ## results in error, FIXME
    lb.data = alist
  else
    #alert "No rows returned. Check your query"
  end
end
## generic edit messagebox
## @param array of column labels
## @param array of data to edit, or blank
## @param array of sqlite3 datatypes (real int text char(9) date)
## @return offset of button pressed and array of LabeledFields
##         0 = ok, 1 = cancel.
##         Use element.text() to get edited value of each element of array
def generic_edit _title, _columns, data, _datatypes
  require 'umbra/messagebox'
  require 'umbra/labeledfield'
  
  array = []       # array of labeledfield we will create, and return
  mb = MessageBox.new title: _title, width: 80 do
    data.each_with_index do |r, ix|
      dt = _datatypes[ix]
      _w, _ml = calc_width_from_datatype( dt )
      $log.debug "  MESSAGE_BOX::: #{_columns[ix]} ==> #{_datatypes[ix]} "

      x =  LabeledField.new label: _columns[ix], name: _columns[ix], text: r, col: 20, width: _w, maxlen: _ml, color_pair: CP_CYAN, attr: REVERSE

      $log.debug "  MESSAGE_BOX::: after create #{_columns[ix]} ==> #{_datatypes[ix]} "
      array << x
      add x
      $log.debug "  MESSAGE_BOX::: after add #{_columns[ix]} ==> #{_datatypes[ix]} "
    end
  end
  ret = mb.run
  return ret, array
end
## Given an sqlite3 datatype, returns width and maximum length.
## Used in messageboxes.
def calc_width_from_datatype dt
  if dt == "text"
    _w = 50
    _ml = 100
  elsif dt == "date"
    _w = 12
    _ml = 20
  elsif dt == "real"
    _w = 10
    _ml = 10
  elsif dt == "int"
    _w = 8
    _ml = 8
  elsif dt.index("char")
    a = dt.match(/(\d+)/)
    _w = a.captures().first.to_i
    _ml = _w
  else
    _w = _ml = 30
  end
  return _w, _ml
end
begin
  include Umbra
  init_curses
  startup
  win = Window.new
  statusline(win, " "*(win.width-0), 0)
  statusline(win, "Press C-q to quit #{win.height}:#{win.width}", 20)
  title = Label.new( :text => "Tennis Query", :row => 0, :col => 0 , :width => FFI::NCurses.COLS-1, 
                    :justify => :center, :color_pair => 0, :attr => REVERSE)

  form = Form.new win
  form.add_widget title

  box = Box.new row: 1, col: 0, width: title.width, height: FFI::NCurses.LINES-2
  #form.position_below(box, label)
  #box.below(title)
  #box.expand_right(0).expand_down(-1)
  #box.expand_down(-1)
  @query = "SELECT rowid, tourney_id, tourney_name, tourney_date, winner_name, loser_name, score, round FROM matches "
  @order_by = "ORDER BY tourney_date, tourney_name, match_num"
  data, columns, datatypes = get_data(@db, "#{@query} #{@order_by}")

  table = Table.new(columns: columns, data: data) do |tt|
    tt.column_hide(0)
    tt.column_hide(1)
    tt.column_width(6, 24)
  end
  #table.column_hide(0)
  #table.column_hide(1)
  #table.column_width(6, 24)
  box.title = "#{table.row_count} rows"
  box.fill table
  tabular = table.tabular
  # this is one way of hiding a column if we don't want to use the hide option.
  # But we have to supply formatstring, and take care of separator and headings too.
  #def tabular.convert_value_to_text row, format_string, index
    #"%-5.5s |%-10.10s |%-12.12s |%-12.12s |%-27.27s |%-27.27s |%-24.24s |%-5.5s" % row
    #"%-12.12s |%-12.12s |%-27.27s |%-27.27s |%-24.24s |%-5.5s" % row[2..-1]
  #end
    #def table._format_value line, index, state
    #end
    def table.color_of_data_row index, state, data_index
      arr = _format_color index, state
      if index == 0                  ## header
        arr = @header_color_pair || [ CP_MAGENTA, REVERSE ]
      elsif data[data_index][-1] == "SF"
        arr = [ CP_WHITE, BOLD | arr[1] ]
      elsif data[data_index][-1] == "F"
        arr = [ CP_YELLOW, BOLD  | arr[1]]
      end
      
      arr
    end
    table.bind_event(:CHANGED) { |obj| box.title = "#{obj.row_count} rows";  }
    table.command do |ix|
      #rowid = table.current_id
      data = table.current_row_as_array
      if data
        #t_id = data[1]
        #t_name = data[2]
        hash = table.current_row_as_hash
        score = hash['score']
        h1 = get_full_row_as_hash(table)
        surface = h1['surface']
        draw = h1['draw_size']
        level = h1['tourney_level']
        #statusline(win, "#{rowid} | #{t_id} | #{t_name}          ")
        statusline(win, data[0..4].join("| ") + " | #{score} | #{surface} | #{draw} | #{level} " )
      end
    end
    table.bind_key( 'v', 'view details') { view_details(table) }
    table.bind_key( ?\C-s, 'filter popup') { filter_popup(table) }


  form.add_widget box, table


  form.pack
  form.repaint
  form.select_first_field
  win.wrefresh

  y = x = 1
  while (ch = win.getkey) != FFI::NCurses::KEY_CTRL_Q
    next if ch == -1
    form.handle_key ch
    #statusline(win, "Pressed #{ch} on     ", 70)
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
