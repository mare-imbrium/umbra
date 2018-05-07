# ----------------------------------------------------------------------------- #
#         File: table.rb
#  Description: widget for tabular data
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-05-06 - 09:56
#      License: MIT
#  Last update: 2018-05-07 15:03
# ----------------------------------------------------------------------------- #
#  table.rb  Copyright (C) 2018 j kepler

##--------- Todo section ---------------
## TODO how to format the header
## TODO formatting rows
## TODO if we want to color specific columns based on values then I think we have to format (render) the row at the last 
##      moment in _print_row and not in advance
#
require 'forwardable'
require 'umbra/tabular'
require 'umbra/textbox'

module Umbra
  ##
  ## A table of columnar data.
  ## This is not truly a table. This is a quick rough take - it contains a tabular object, and a 
  ##  textbox, and delegates most calls to these.
  #
  class Table < Listbox

    extend Forwardable


    attr_accessor :tabular
    attr_accessor :header_color_pair, :header_attr
    attr_accessor :rendered                 ## boolean, if data has changed, we need to re-render

    # if a variable has been defined, off and on value will be set in it (default 0,1)
    # FIXME we can't have config and args !!!
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
    end
    def render
      @data_offset = 0
      @data_offset +=1 if @tabular.use_separator
      @data_offset +=1 if @tabular.columns
      self.list = @tabular.render
    end
    def repaint
      render if !@rendered
      super

      @rendered = true
    end

    # how to print the header or separator
    def color_of_header_row index, state
        arr =  [ @header_color_pair || CP_MAGENTA, @header_attr || REVERSE ] 
        return arr if index == 0
        [ arr[0], NORMAL ]
    end
    def color_of_data_row index, state, data_index
      _format_color(index, state)         ## calling superclass here
    end
    def _print_row(win, row, col, str, index, state)
      if index <= @data_offset - 1
        _print_headings(win, row, col, str, index, state)
      else
        data_index = index - @data_offset  ## index into actual data object
        _print_data(win, row, col, str, index, state, data_index)
      end
    end
    def _print_headings(win, row, col, str, index, state)
      arr = color_of_header_row(index, state)
      win.printstring(row, col, str, arr[0], arr[1])
    end
    ## prints the data
    ## index is index into visual row, starting 0 for headings, and 1 for separator
    ## data_index is index into actual data object. Use this if checking actual data array
    def _print_data(win, row, col, str, index, state, data_index)
      data_index = index - @data_offset  ## index into actual data object
      arr = color_of_data_row(index, state, data_index)
      #arr = _format_color(index, state)
      win.printstring(row, col, str, arr[0], arr[1])
    end
    def color_of_column ix, value, defaultcolor
    end
    ## returns the raw data as array of arrays in tabular
    def data
      @tabular.list
    end
    def data=(list)
      @rendered = false
      @tabular.data = list
    end
    def_delegators :@tabular, :headings=, :columns= , :add, :add_row, :<< , :column_width, :align_column, :convert_value_to_text, :separator, :to_s, :x=, :y=
    def_delegators :@tabular, :columns , :numbering

  end # class 
end # module
