require 'umbra/multiline'
# ----------------------------------------------------------------------------- #
#         File: listbox.rb
#  Description: list widget that displays a scrollable list of items that is selectable.
#       Author: j kepler  http://github.com/mare-imbrium/umbra
#         Date: 2018-03-19 
#      License: MIT
#  Last update: 2018-05-14 14:32
# ----------------------------------------------------------------------------- #
#  listbox.rb  Copyright (C) 2012-2018 j kepler
#  == TODO 
#  currently only do single selection, we may do multiple at a later date. TODO
#  insert/delete a row ??
## Other selection functions: select_all, select(n), deselect(n), selected?(n), select(m,n,o...), select(String),
##    select(Range). Same with deselect.
#  ----------------
module Umbra

  ## Display a list of items.
  ## Adds selection capability to the Scrollable widget.
  #
  class Listbox < Multiline 

    attr_accessor :selection_allowed           # does this class allow row selection (should be class level)
    attr_accessor :selection_key               # key used to select a row
    attr_accessor :selected_index              # row selected, may change to plural
    attr_property :selected_color_pair         # row selected color_pair
    attr_property :selected_attr               # row selected color_pair
    attr_accessor :selected_mark               # row selected character
    attr_accessor :unselected_mark             # row unselected character (usually blank)
    attr_accessor :current_mark                # row current character (default is >)

    def initialize config={}, &block

      @selection_allowed  = true               # does this class allow selection of row
      @selected_index     = nil                # index of row selected
      @selection_key      = ?s.getbyte(0)      # 's' used to select/deselect
      @selected_color_pair = CP_RED 
      @selected_attr      = REVERSE
      @selected_mark      = 'x'                # row selected character
      @unselected_mark    = ' '                # row unselected character (usually blank)
      @current_mark       = '>'                # row current character (default is >)
      register_events([:LIST_SELECTION_EVENT])
      super
    end


    def list=(alist)
      super
      clear_selection
    end


    def clear_selection
      @selected_index = nil
    end

    def map_keys
      return if @keys_mapped
      if @selection_allowed and @selection_key
        bind_key(@selection_key, 'toggle_selection')   { toggle_selection }
      end
      super
    end

    def toggle_selection
      @repaint_required = true  
      if @selected_index == @current_index 
        @selected_index = nil
      else
        @selected_index = @current_index 
      end
      fire_handler :LIST_SELECTION_EVENT, self   # use selected_index to know which one
    end

    ## listbox adds a mark on the side, whether a row is selected or not, and whether it is current.
    def paint_row(win, row, col, line, ctr, state)

      f = _format_value(line, ctr, state)

      mark = _format_mark(ctr, state)
      ff = "#{mark}#{f}"

      ff = _truncate_to_width( ff )   ## truncate and handle panning

      _print_row(win, row, col, ff, ctr, state)
    end

    def state_of_row ix
      _st = super
      if ix == @selected_index
        _st = :SELECTED
      end # 
      _st
    end 


    def _format_mark index, state
      mark = case state
             when :SELECTED
               @selected_mark
             when :HIGHLIGHTED, :CURRENT
               @current_mark
             else
               @unselected_mark
             end
    end
    alias :mark_of_row :_format_mark 

    def OLD_format_value line, ctr, state
      mark = _format_mark(ctr, state)
      line = "#{mark}#{line}"
    end


    def _format_color index, state
      arr = super
      if state == :SELECTED
        arr = [@selected_color_pair, @selected_attr]
      end
      arr
    end


=begin
    def cursor_forward
      blen = current_row().size-1
      @pcol += 1 if @pcol < blen
    end
    def cursor_backward
      @pcol -= 1 if @pcol > 0
    end
=end


  end 
end # module
