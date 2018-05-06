# ----------------------------------------------------------------------------- #
#         File: table.rb
#  Description: widget for tabular data
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-05-06 - 09:56
#      License: MIT
#  Last update: 2018-05-06 12:34
# ----------------------------------------------------------------------------- #
#  table.rb  Copyright (C) 2018 j kepler

##--------- Todo section ---------------
## TODO how to format the header
## TODO formatting rows
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
  class Table < Textbox

    extend Forwardable


    attr_accessor :tabular
    # if a variable has been defined, off and on value will be set in it (default 0,1)
    # FIXME we can't have config and args !!!
    def initialize cols=nil, *args, &block
      @tabular = Tabular.new cols, *args
      config = {}
      @rendered = nil
      super config, &block
    end
    def render
      self.list = @tabular.render
    end
    def repaint
      render if !@rendered
      super

      @rendered = true
    end
    def_delegators :@tabular, :headings=, :columns= , :add, :add_row, :<< , :column_width, :align_column, :data=, :convert_value_to_text, :separator, :to_s, :x=, :y=
    def_delegators :@tabular, :columns , :numbering

  end # class 
end # module
