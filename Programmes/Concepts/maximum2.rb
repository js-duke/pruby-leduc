$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

def jiggle
  sleep rand / 10.0
end

mutex = Mutex.new

a = [10, 62, 173, 823, 32, 99, 9292, 0, 1]

m = 0
PRuby.pcall (0...a.size),
->( i ) { if a[i] > m 
            mutex.synchronize do
              m = a[i] if a[i] > m
            end
          end
        }

puts "maximum = #{m}"
