# ----------------------------------------------------------------------------- #
#         File: table.rb
#  Description: widget for tabular data
#       Author: j kepler  http://github.com/mare-imbrium/umbra/
#         Date: 2018-05-06 - 09:56
#      License: MIT
#  Last update: 2018-05-19 12:07
# ----------------------------------------------------------------------------- #
#  table.rb  Copyright (C) 2018 j kepler

##--------- Todo section ---------------
## TODO w - next column, b - previous column
## TODO paint lines as column separators. issue is panning.
## TODO starting visual column (required when scrolling)
## TODO change a value value_at(x,y, value) ; << ; delete_at 
## TODO change column width interactively, hide column , move column
## TODO maybe even column_color(n, color_pair, attr)
## TODO sort on column/s.
## TODO selection will have to be added. maybe we should have extended listbox after all. Or made multiline selectable.
## DONE how to format the header
## DONE formatting rows
## DONE if we want to color specific columns based on values then I think we have to format (render) the row at the last 
##      moment in print_row and not in advance
## NOTE: we are setting the data in tabular, not list. So calling list() will give nil until a render has happened.
##     callers will have to use data() instead of list() which is not consistent.
## NOTE: current_index in this object refers to index including header and separator. It is not the offset in the data array.
##    For that we need to adjust with @data_offset.
#
require 'forwardable'
require 'umbra/tabular'
require 'umbra/multiline'

module Umbra
  ##
  ## A table of columnar data.
  ## This is not truly a table. This is a quick rough take - it contains a tabular object, and  
  ##  extends Multiline.
  #
  class Table < Multiline

    extend Forwardable


    ## tabular is the data model for Table.
    ## It may be passed in in the constructor, or else is created when columns and data are passed in.
    attr_accessor :tabular

    ## color pair and attribute for header row
    attr_accessor :header_color_pair, :header_attr

    attr_accessor :rendered                 ## boolean, if data has changed, we need to re-render

    
    ## Create a Table object passing either a Tabular object or columns and list
    ## e.g. Table.new tabular: tabular
    ##      Table.new columns: cols, list: mylist
    ##
    def initialize config={}, &block
      if config.key? :tabular
        @tabular = config.delete(:tabular)
      else
        cols = config.delete(:columns)
        data = config.delete(:list)
        @tabular = Tabular.new cols
        if data
          @tabular.data = data
        end
      end
      @rendered = nil
      super

      ## NOTE: a tabular object should be existing at this point.
    end

    ## returns the raw data as array of arrays in tabular
    def data
      @tabular.list
    end


    def data=(list)
      @rendered = false
      @tabular.data = list
      @repaint_required = true
      self.focusable = true
      @pstart = @current_index = 0
      @pcol               = 0
    $log.debug "  before table data= CHANGED "
      #fire_handler(:CHANGED, self)    ## added 2018-05-08 - 
    end

    ## render the two-dimensional array of data as an array of Strings.
    ## Calculates data_offset which is the row offset from which data starts.
    def render
      @data_offset = 0
      @data_offset +=1 if @tabular.use_separator
      @data_offset +=1 if @tabular.columns
      self.list = @tabular.render
    end

    ## paint the table
    def repaint
      render if !@rendered
      super

      @rendered = true
    end

    ## Specify how to print the header and separator.
    ## index can be 0 or 1
    ## returns an array of color_pair and attribute
    def color_of_header_row index, state
        arr =  [ @header_color_pair || CP_MAGENTA, @header_attr || REVERSE ] 
        return arr if index == 0
        [ arr[0], NORMAL ]
    end

    ## Specify how the data rows are to be coloured.
    ## Override this to have customised row coloring.
    ## @return array of color_pair and attrib.
    def color_of_data_row index, state, data_index
      color_or_row(index, state)         ## calling superclass here
    end

    ## Print the row which could be header or data
    ## @param index [Integer] - index of list, starting with header and separator
    def print_row(win, row, col, str, index, state)
      if index <= @data_offset - 1
        _print_headings(win, row, col, str, index, state)
      else
        data_index = index - @data_offset  ## index into actual data object
        _print_data(win, row, col, str, index, state, data_index)
      end
    end

    ## Print the header row
    ## index [Integer] - should be 0 or 1 (1 for optional separator)
    def _print_headings(win, row, col, str, index, state)
      arr = color_of_header_row(index, state)
      win.printstring(row, col, str, arr[0], arr[1])
    end



    ## Print the data.
    ## index is index into visual row, starting 0 for headings, and 1 for separator
    ## data_index is index into actual data object. Use this if checking actual data array
    def _print_data(win, row, col, str, index, state, data_index)
      data_index = index - @data_offset  ## index into actual data object
      arr = color_of_data_row(index, state, data_index)

      win.printstring(row, col, str, arr[0], arr[1])
    end
    def color_of_column ix, value, defaultcolor
      raise "unused yet"
    end



    def row_count
      @tabular.list.size
    end


    ## return rowid (assumed to be first column)
    def current_id
      data = current_row_as_array()
      return nil unless data
      data.first
    end
    # How do I deal with separators and headers here - return nil
    ## This returns all columns including hidden so rowid can be accessed
    def current_row_as_array
      data_index = @current_index - @data_offset  ## index into actual data object
      return nil if data_index < 0                ## separator and heading
      data()[data_index]
    end

    ## returns the current row as a hash with column name as key.
    def current_row_as_hash
      data = current_row_as_array
      return nil unless data
      columns = @tabular.columns
      hash = columns.zip(data).to_h
    end

    ## delegate calls to the tabular object
    def_delegators :@tabular, :headings=, :columns= , :add, :add_row, :<< , :column_width, :column_align, :column_hide, :convert_value_to_text, :separator, :to_string, :x=, :y=, :column_unhide
    def_delegators :@tabular, :columns , :numbering
    def_delegators :@tabular, :column_hidden, :delete_at, :value_at

  end # class 
end # module

#  vim:  comments=sr\:##,mb\:##,el\:#/,\:## :
