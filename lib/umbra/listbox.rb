require 'umbra/multiline'
# ----------------------------------------------------------------------------- #
#         File: listbox.rb
#  Description: list widget that displays a list of items
#       Author: j kepler  http://github.com/mare-imbrium/canis/
#         Date: 2018-03-19 
#      License: MIT
#  Last update: 2018-05-09 10:56
# ----------------------------------------------------------------------------- #
#  listbox.rb  Copyright (C) 2012-2018 j kepler
#  == TODO 
#  currently only do single selection, we may do multiple at a later date. TODO
#  insert/delete a row ??
#  ----------------
module Umbra
  class Listbox < Multiline 


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
