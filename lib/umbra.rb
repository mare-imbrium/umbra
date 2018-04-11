require "umbra/version"
#require 'ffi-ncurses'
require "umbra/window"
require "umbra/form"

module Umbra
  def alert str, config={}
    require 'umbra/dialog'
    title = config[:title] || "Alert"
    cp    = config[:color_pair] || create_color_pair( COLOR_BLUE, COLOR_WHITE )
    attr  = config[:attrib]     || NORMAL
    m = Dialog.new text: str, title: title, window_color_pair: cp, window_attr: attr
    m.run
  end

  # view an array in a popup window
  def view array, config={}
    require 'umbra/pad'
    title = config[:title] || "Viewer"
    cp    = config[:color_pair] || create_color_pair( COLOR_BLUE, COLOR_WHITE )
    attr  = config[:attrib]     || NORMAL
    m = Pad.new list: array, height: FFI::NCurses.LINES-2, width: FFI::NCurses.COLS-10, title: title, color_pair: cp, attrib: attr
    m.run
  end
end
