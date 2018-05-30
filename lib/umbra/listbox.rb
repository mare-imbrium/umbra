require 'umbra/multiline'
# ----------------------------------------------------------------------------- #
#         File: listbox.rb
#  Description: list widget that displays a scrollable list of items that is selectable.
#       Author: j kepler  http://github.com/mare-imbrium/umbra
#         Date: 2018-03-19 
#      License: MIT
#  Last update: 2018-05-30 10:08
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
  ## Adds selection capability to the Multiline widget.
  ## Adds event :SELECT_ROW which fires on selection and unselection.
  #
  class Listbox < Multiline 

    attr_accessor :selection_allowed           # does this class allow row selection (should be class level)
    attr_accessor :selection_key               # key used to select a row
    attr_reader   :selected_index              # row selected, may change to plural
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
      #register_events([:LIST_SELECTION_EVENT])
      register_events([:SELECT_ROW])
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

    ## Toggle current row's selection status.
    def toggle_selection _row=@current_index
      @repaint_required = true  
      if @selected_index == _row
        unselect_row _row
      else
        select_row _row
      end
    end

    ## select given row
    def select_row _row=@current_index
      @selected_index = _row
      fire_handler :SELECT_ROW, self   # use selected_index to know which one
    end
    
    ## unselect given row
    def unselect_row _row=@current_index
      if _row == @selected_index
        @selected_index = nil
        fire_handler :SELECT_ROW, self   # use selected_index to know which one
      end
    end

    ## Paint the row.
    ## For any major customization of Listbox output, this method would be overridden.
    ## This method determines state, mark, slice of line item to show.
    ## listbox adds a mark on the side, whether a row is selected or not, and whether it is current.
    ## @param win - window pointer for printing
    ## @param [Integer] - row offset on screen
    ## @param [Integer] - col offset on screen
    ## @param [String]  - line to print
    ## @param [Integer] - offset in List array
    def paint_row(win, row, col, line, index)

      state = state_of_row(index)     

      f = value_of_row(line, index, state)

      mark = mark_of_row(index, state)
      ff = "#{mark}#{f}"

      ff = _truncate_to_width( ff )   ## truncate and handle panning

      print_row(win, row, col, ff, index, state)
    end

    ## Determine state of the row
    ## Listbox adds :SELECTED state to Multiline.
    ## @param [Integer] offset of row in data
    def state_of_row index
      _st = super
      if index == @selected_index
        _st = :SELECTED
      end # 
      _st
    end 


    ## Determine the mark on the left of the row. 
    ## The mark depends on the state: :SELECTED :HIGHLIGHTED :CURRENT :NORMAL
    ## Listbox adds :SELECTED state to Multiline.
    ## @param [Integer] offset of row in data
    ## @return character to be displayed inside left margin
    def mark_of_row index, state
      mark = case state
             when :SELECTED
               @selected_mark
             when :HIGHLIGHTED, :CURRENT
               @current_mark
             else
               @unselected_mark
             end
    end
    alias :_format_mark :mark_of_row 


    ## Determine color and attribute of row.
    ## Overriding this allows application to have customized row colors based on data
    ##  which can be determined using +index+.
    ## Listbox adds :SELECTED state to +Multiline+.
    ## @param [Integer] offset of row in data
    ## @return [Array] color_pair and attrib constant
    def color_of_row index, state
      arr = super
      if state == :SELECTED
        arr = [@selected_color_pair, @selected_attr]
      end
      arr
    end



  end  # class
end # module
#  vim:  comments=sr\:##,mb\:##,el\:#/,\:## :
