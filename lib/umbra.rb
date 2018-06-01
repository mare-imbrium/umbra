require "umbra/version"
#require 'ffi-ncurses'
require "umbra/window"
require "umbra/form"

module Umbra

  def curses
    FFI::NCurses
  end

  def alert str, config={}
    require 'umbra/dialog'

    config[:text]              ||= str
    config[:title]             ||= "Alert"
    config[:window_color_pair] ||=  create_color_pair( COLOR_BLUE, COLOR_WHITE )
    config[:window_attr]       ||= NORMAL
    config[:buttons]           ||= ["Ok"]

    #m = Dialog.new text: str, title: title, window_color_pair: cp, window_attr: attr
    m = Dialog.new config
    m.run
  end

  # confirmation dialog which prompts message with Ok and Cancel and returns true or false.
  def confirm str, config={}
    require 'umbra/dialog'

    config[:text]              ||= str
    config[:title]             ||= "Confirm"
    config[:window_color_pair] ||=  create_color_pair( COLOR_BLUE, COLOR_WHITE )
    config[:window_attr]       ||= NORMAL
    config[:buttons]           ||= ["Ok", "Cancel"]

    m = Dialog.new config
    ret = m.run
    return ret == 0
  end

  ## Pop up a dialog with an array, such as an exception
  def textdialog array, config={}
    require 'umbra/messagebox'
    config[:title]             ||= "Alert"
    config[:buttons]           ||= ["Ok"]

    mb = MessageBox.new config do
      text array
    end
    mb.run
  end

  # view an array in a popup window
  def view array, config={}, &block
    require 'umbra/pad'
    config[:title] ||= "Viewer"
    config[:color_pair] ||= create_color_pair( COLOR_BLUE, COLOR_WHITE )
    config[:attrib]     ||= NORMAL
    config[:list]       = array
    config[:height]     ||= FFI::NCurses.LINES-2
    config[:width]      ||= FFI::NCurses.COLS-10
    #m = Pad.new list: array, height: FFI::NCurses.LINES-2, width: FFI::NCurses.COLS-10, title: title, color_pair: cp, attrib: attr
    m = Pad.new config, &block
    m.run
  end

  ## create a logger instance given a path, return the logger
  ## NOTE: Ideally would like to set $log here to this, but what if user creates multiple.
  def create_logger path, config={}
    require 'logger'
    _path   = File.open(path, File::WRONLY|File::TRUNC|File::CREAT) 
    logg = Logger.new(_path)
    raise "Could not create logger: #{path}" unless logg
    ## if not set, will default to 0 which is debug. Other values are 1 - info, 2 - warn
    logg.level = config[:level] ||  ENV["UMBRA_LOG_LEVEL"].to_i
    #logg.info "START -- #{$0} log level: #{logg.level}. To change log level, increase UMBRA_LOG_LEVEL in your environment to 1 or 2 or 3."
    return logg
  end

  ## Trying out a key loop to simplify matters for user. NOT TESTED.
  ## @yield key pressed if block given, else calls form.handle_key(ch).
  def main_loop form, &block
    win = form.window
    form.repaint
    win.wrefresh
    stopping = false
    while true
      catch :close do
        while( ch = win.getkey) != 999
          next if ch == -1      ## should we put this here ???
          begin
            if ch == curses::KEY_CTRL_Q
              stopping = true 
              break
            end
            if block_given?
              yield ch
            else
              form.handle_key ch
            end
          rescue => err
            if $log
              $log.debug( "loop in umbra.rb handle_key rescue reached ")
              $log.debug( err.to_s) 
              $log.debug(err.backtrace.join("\n")) 
            end
            textdialog [err.to_s, *err.backtrace], :title => "Exception"
          end
          win.wrefresh
        end
        #stopping = win.fire_close_handler  ## TODO next version
        #win.wrefresh
        break if stopping
      end
      break if stopping
    end
  end


end   # module
