$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

def jiggle
  sleep rand / 10.0
end

PRuby.pcall \
  -> { puts "Thr1: ."
       jiggle
       puts "Thr1: .."
       jiggle
       puts "Thr1: ..."
  },
  -> { puts "Thr2: +"
       jiggle
       puts "Thr2: ++"
       jiggle
       puts "Thr2: +++"
  }

puts "Fin du programme"
