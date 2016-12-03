$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

def jiggle
  sleep rand / 10.0
end

x = 0

PRuby.pcall \
  -> { jiggle
       tmp = x
       jiggle
       x = tmp + 1
  },
  -> { jiggle
       tmp = x
       jiggle
       x = tmp + 2
  }

puts "x = #{x}"
