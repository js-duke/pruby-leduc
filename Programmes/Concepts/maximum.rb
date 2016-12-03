$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

def jiggle
  sleep rand / 10.0
end

a = [10, 62, 173, 823, 32, 99, 9292, 0, 1]

m = 0
PRuby.pcall (0...a.size),
  ->( i ) { if a[i] > m then jiggle; m = a[i] end }

puts "maximum = #{m}"
