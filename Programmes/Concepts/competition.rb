$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

x = 0

PRuby.pcall \
  -> { x += 1 },
  -> { x += 2 }

puts "x = #{x}"
