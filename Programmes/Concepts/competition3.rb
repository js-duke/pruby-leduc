$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

mutex = Mutex.new

x = 0

PRuby.pcall \
  -> { mutex.synchronize { x += 1 } },
  -> { mutex.synchronize { x += 2 } }

puts "x = #{x}"
