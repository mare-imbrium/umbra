# ----------------------------------------------------------------------------- #
#         File: textbox.rb
#  Description: a multiline text view
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-24 - 12:39
#      License: MIT
#  Last update: 2018-05-30 12:47
# ----------------------------------------------------------------------------- #
#  textbox.rb  Copyright (C) 2012-2018 j kepler
##  Todo -----------------------------------
## TODO w and b for next and previous word movement
#
#  ----------------------------------------
## CHANGELOG
# 2018-05-30 - giving self during cursor movement
#  ----------------------------------------
require 'umbra/multiline'
module Umbra
class Textbox < Multiline 
  attr_accessor :file_name            # filename passed in for reading
  #attr_accessor :cursor              # position of cursor in line ??

  def initialize config={}, &block
    @highlight_attr     = FFI::NCurses::A_BOLD
    @row_offset         = 0
    @col_offset         = 0
    @curpos             = 0                  # current cursor position in buffer (NOT screen/window/field)

    register_events([:CURSOR_MOVE]) # movement of cursor left or right, up down or panning.
    super

  end


  # set list of data to be displayed from filename.  {{{
  # NOTE this can be called again and again, so we need to take care of change in size of data
  # as well as things like current_index and selected_index or indices.
  def file_name=(fp)
    raise "File #{fp} not readable"  unless File.readable? fp 
    return Dir.new(fp).entries if File.directory? fp
    case File.extname(fp)
    when '.tgz','.gz'
      cmd = "tar -ztvf #{fp}"
      content = %x[#{cmd}]
    when '.zip'
      cmd = "unzip -l #{fp}"
      content = %x[#{cmd}]
    when '.jar', '.gem'
      cmd = "tar -tvf #{fp}"
      content = %x[#{cmd}]
    when '.png', '.out','.jpg', '.gif','.pdf'
      content = "File #{fp} not displayable"
    when '.sqlite'
      cmd = "sqlite3 #{fp} 'select name from sqlite_master;'"
      content = %x[#{cmd}]
    else
      #content = File.open(fp,"r").readlines # this keeps newlines which mess with output
      content = File.open(fp,"r").read.split("\n")
    end
    self.list = content
    raise "list not set" unless @list

  end # }}}

  # returns current row
  def current_row
    @list[@current_index]
  end


  ## textbox key handling  
  ## Textbox varies from multiline in that it fires a cursor_move event whrease the parent 
  ##  fires a cursor_move event which is mostly used for testing out
  def handle_key ch
    begin 
      ret = super
      return ret
    ensure
      if @repaint_required
        ## this could get fired even if color changed or something not related to cursor moving. FIXME
        ## Should this fire if users scrolls but does not change cursor position
        #fire_handler(:CURSOR_MOVE, [@col_offset, @current_index, @curpos, @panned_cols, ch ])     # 2018-03-25 - improve this
        fire_handler(:CURSOR_MOVE, self)          ## 2018-05-30 - made this like most others yielding self
      end
    end
  end

end 
end # module

#  vim:  comments=sr\:##,mb\:##,el\:#/,\:## :
