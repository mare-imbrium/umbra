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
end
