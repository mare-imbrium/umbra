require "umbra/version"
#require 'ffi-ncurses'
require "umbra/window"
require "umbra/form"

module Umbra
  def alert str, config={}
    require 'umbra/dialog'
    #title = config[:title] || "Alert"
    #cp    = config[:color_pair] || create_color_pair( COLOR_BLUE, COLOR_WHITE )
    #attr  = config[:attrib]     || NORMAL

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
end
