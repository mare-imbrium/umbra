#!/usr/bin/env ruby -w
=begin
  * Name          : A Quick take on tabular data. Readonly.
  * Description   : To show tabular data inside a control, rather than going by the huge
                    Table object, I want to create a simple, minimal table data generator.
                    This will be thrown into a TextView for the user to navigate, select
                    etc.
                    I would use this applications where the tabular data is fairly fixed
                    not where i want the user to select columns, move them, expand etc.
  *               :
  * Author        : jkepler
  * Date          : 
  * Last Update   : 2018-05-31 16:16
  * License       : MIT
=end

## Todo Section --------------
## What if user wishes to supply formatstring and override ours
## ---------------------------


# A simple tabular data generator. Given table data in arrays and a column heading row in arrays, it 
# quickely generates tabular data. It only takes left and right alignment of columns into account.
#   You may specify individual column widths. Else it will take the widths of the column names you supply 
# in the startup array. You are encouraged to supply column widths.
#   If no columns are specified, and no widths are given, it take the widths of the first row 
# as a model to determine column widths. 
#
module Umbra

  class Tabular
    GUESSCOLUMNS = 30

    def yield_or_eval &block
      return unless block
      if block.arity > 0
        yield self
      else
        self.instance_eval(&block)
      end
    end


    ## stores column info internally: name, width and alignment
    class ColumnInfo < Struct.new(:name, :width, :index, :offset, :align, :hidden) 
    end




    ## an array of column titles
    attr_reader :columns

    ## data which is array of arrays: rows and columns
    attr_reader :list

    # boolean, does user want lines numbered
    attr_accessor :numbering

    attr_accessor :use_separator          ## boolean. Use a separator line after heading or not.

    # x is the + character used a field delim in separators
    # y is the field delim used in data rows, default is pipe or bar
    attr_accessor :x, :y

    # takes first optional argument as array of column names
    # second optional argument as array of data arrays
    # @yield self
    #
    def initialize cols=nil, *args, &block
      @chash             = []                 # hash of column info, not used
      @_skip_columns     = {}                 # internal, which columns not to calc width of since user has specified
      @separ = @columns = @numbering =  nil
      @y = '|'
      @x = '+'
      @use_separator = false
      @_hidden_columns_flag = false
      self.columns = cols if cols
      if !args.empty?
        self.data = args
      end
      yield_or_eval(&block) if block_given?
    end
    #
    # set columns names .
    ## NOTE that we are not clearing chash here. In case, someone changes table and columns.
    # @param [Array<String>] column names, preferably padded out to width for column
    def columns=(array)
      #$log.debug "tabular got columns #{array.count} #{array.inspect} " if $log
      @columns = array
      @columns.each_with_index { |e,i| 
        #@chash[i] = ColumnInfo.new(c, c.to_s.length) 
        c = get_column(i)
        c.name = e
        c.width = e.to_s.length
        #@chash[i] = c
        #@cw[i] ||= c.to_s.length
        #@calign[i] ||= :left # 2011-09-27 prevent setting later on
      }
    end
    alias :headings= :columns=
    #
    # set data as an array of arrays
    # @param [Array<Array>] data as array of arrays
    def data=(list)
      #puts "got data: #{list.size} " if !$log
      #puts list if !$log
      @list = list
    end

    # add a row of data 
    # @param [Array] an array containing entries for each column
    def add array
      #$log.debug "tabular got add  #{array.count} #{array.inspect} " if $log
      @list ||= []
      @list << array
    end
    alias :<< :add
    alias :add_row :add

    # retrieve the column info structure for the given offset. The offset
    # pertains to the visible offset not actual offset in data model. 
    # These two differ when we move a column.
    # @return ColumnInfo object containing width align color bgcolor attrib hidden
    def get_column index
      return @chash[index] if @chash[index]
      # create a new entry since none present
      c = ColumnInfo.new
      c.index = index
      @chash[index] = c
      return c
    end
    # set width of a given column, any data beyond this will be truncated at display time.
    # @param [Number] column offset, starting 0
    # @param [Number] width
    def column_width colindex, width=:NONE
      if width == :NONE
        #return @cw[colindex]
        return get_column(colindex).width
      end
      @_skip_columns[colindex] = true   ## don't calculate col width for this.
      get_column(colindex).width = width
      self
    end

    def column_hidden colindex, flag=:NONE
      if flag == :NONE
        return get_column(colindex).hidden
        #return @chide[colindex]
      end
      @_hidden_columns_flag = true if flag
      #@chide[colindex] = flag
      get_column(colindex).hidden = flag
      self
    end

    # set alignment of given column offset
    # @param [Number] column offset, starting 0
    # @param [Symbol] :left, :right
    def column_align colindex, lrc=:NONE
      if lrc == :NONE
        return get_column(colindex).align
        #return @calign[colindex]
      end
      raise ArgumentError, "wrong alignment value sent" if ![:right, :left, :center].include? lrc
      get_column(colindex).align = lrc
      self
    end

    ## return an array of visible columns names
    def visible_column_names
      visible = []
      @chash.each_with_index do |c, ix|
        if !c.hidden
          if block_given?
            yield c.name, ix 
          else
            visible << c.name
          end
        end
      end
      return visible unless block_given?
    end

    ## returns the count of visible columns based on column names.
    ## NOTE: what if no column names gives ???
    def column_count
      visible_column_names().count
    end

    # yields non-hidden columns (ColumnInfo) and the offset/index
    # This is the order in which columns are to be printed
    def each_column
      @chash.each_with_index { |c, i| 
        next if c.hidden
        yield c,i if block_given?
      }
    end

    ## for the given row, return visible columns as an array
    ## @yield column and index
    def visible_columns(row)
      visible = []
      row.each_with_index do |e, ix|
        hid = @chash[ix].hidden
        if !hid
          if block_given?
            yield e, ix
          else
            visible << e 
          end
        end
      end
      return visible if !block_given?
    end

    # 
    # Now returns an array with formatted data
    # @return [Array<String>] array of formatted data
    def render
      raise "tabular:: list is nil " unless @list
      $log.debug "  render list:: #{@list.size} "
      #$log.debug "  render list:1: #{@list} "
      raise "tabular:: columns is nil " unless @columns
      buffer = []
      @separ = nil
      _guess_col_widths
      rows = @list.size.to_s.length
      #@rows = rows
      fmstr = _prepare_format
      $log.debug "tabular: fmstr:: #{fmstr}"
      $log.debug "tabular: cols: #{@columns}"
      #$log.debug "tabular: data: #{@list}"

      str = ""
      if @numbering
        str = " "*(rows+1)+@y
      end
      #str <<  fmstr % visible_column_names()
      str <<  convert_heading_to_text(visible_column_names(), fmstr)
      buffer << str
      #puts "-" * str.length
      buffer << separator if @use_separator
      if @list    ## XXX why wasn't numbering done in _prepare_format ???? FIXME
        if @numbering
          fmstr = "%#{rows}d "+ @y + fmstr
        end
        #@list.each { |e| puts e.join(@y) }
        count = 0
        @list.each_with_index { |r,i|  
          if r == :separator
            buffer << separator
            next
          end
          if @_hidden_columns_flag
            r = visible_columns(r)
          end
          if @numbering
            r.insert 0, count+1
          end
          #value = convert_value_to_text r, count
          value = convert_value_to_text r, fmstr, i
          buffer << value
          count += 1
        }
      end
      buffer
    end

    ## render_row
    ## @param [Array] row as Array
    ## @param [String] format string
    ## @param [Integer] row offset in data
    def convert_value_to_text r, fmstr, index
      return fmstr % r;  
    end
    def convert_heading_to_text r, fmstr
      return fmstr % r;  
    end
    # use this for printing out on terminal
    # NOTE: Do not name this to_s as it will print the entire content in many places in debug statements
    # @example
    #     puts t.to_s
    def to_string
      render().join "\n"
    end

    def value_at x,y, value=:NONE
      if value == :NONE
        return @list[x, y]
      end
      @list[x, y] = value
    end
    def delete_at ix
      return unless @list
      raise ArgumentError, "Argument must be within 0 and #{@list.length}" if ix < 0 or ix >=  @list.length 
      #fire_dimension_changed
      #@list.delete_at(ix + @_header_adjustment)
      @list.delete_at(ix)
    end




    def add_separator
      @list << :separator
    end

    ## This refers to a separator line after the heading  and not a field separator.
    ## Badly named !
    def separator
      return @separ if @separ
      str = ""
      if @numbering
        str = "-"*(rows+1)+@x
      end
      each_column { | c, ix|
        v = c.width
        next if v == 0     ## hidden column
        str << "-" * (v+1) + @x 
      }
      @separ = str.chop
    end

    ## This calculates and stores the offset at which each column starts.
    ## Used when going to next column or doing a find for a string in the table.
    def _calculate_column_offsets
      total = 0
      coffsets = []
      ctr = 0
      ## ix will have gaps in between for hidden fields
      each_column { | c, ix|
        v = c.width
        coffsets[ctr] = total
        ctr += 1
        total += v + 2                         ## blank space plus separator
      }
      return coffsets
    end


    private
    def _guess_col_widths  #:nodoc:
      @list.each_with_index { |r, i| 
        break if i > GUESSCOLUMNS
        next if r == :separator
        r.each_with_index { |c, j|
          ## we need to skip those columns which user has specified
          next if @_skip_columns[j] == true
          #next if @chide[j]
          next if @chash[j].hidden
          x = c.to_s.length
          w = @chash[j].width
          if !w
            @chash[j].width = x
          else
            @chash[j].width = x if x > w
          end
        }
      }
    end

    ## prepare formatstring.
    ## NOTE: this is not the final value.
    ## render adds numbering to this, if user has set numbering option.!!!!
    def _prepare_format  #:nodoc:
      fmstr = nil
      fmt = []
      each_column { |c, i|
        ## trying a zero for hidden columns
        ## worked but an extra space is added below and the sep
        w = c.width
        case c.align
        when :right
          #fmt << "%.#{w}s "
          fmt << "%#{w}.#{w}s "
        else
          fmt << "%-#{w}.#{w}s "
        end
      }
      ## the next line will put a separator after hidden columns also
      fmstr = fmt.join(@y)
      #puts "format: #{fmstr} " # 2011-12-09 23:09:57
      return fmstr
    end
  end
end

if __FILE__ == $PROGRAM_NAME
  include Umbra
  $log = nil
  t = Tabular.new(['a', 'b'], [1, 2], [3, 4])
  puts t.to_string
  puts 
  t = Tabular.new([" Name ", " Number ", "  Email    "])
  t.add %w{ rahul 32 r@ruby.org }
  t << %w{ _why 133 j@gnu.org }
  t << %w{ Jane 1331 jane@gnu.org }
  t.column_width 1, 10
  t.column_align 1, :right
  puts t.to_string
  puts

  s = Tabular.new do |b|
    b.columns = %w{ country continent text }
    b << ["india","asia","a warm country" ] 
    b << ["japan","asia","a cool country" ] 
    b << ["russia","europe","a hot country" ] 
    b.column_width 2, 30
  end
  puts s.to_string
  puts
  puts "::::"
  puts
  s = Tabular.new do |b|
    b.columns = %w{ place continent text }
    b << ["india","asia","a warm country" ] 
    b << ["japan","asia","a cool country" ] 
    b << ["russia","europe","a hot country" ] 
    b << ["sydney","australia","a dry country" ] 
    b << ["canberra","australia","a dry country" ] 
    b << ["ross island","antarctica","a dry country" ] 
    b << ["mount terror","antarctica","a windy country" ] 
    b << ["mt erebus","antarctica","a cold place" ] 
    b << ["siberia","russia","an icy city" ] 
    b << ["new york","USA","a fun place" ] 
    b.column_width 0, 12
    b.column_width 1, 12
    b.numbering = true
  end
  puts s.to_string
end

#  vim:  comments=sr\:##,mb\:##,el\:#/,\:## :
