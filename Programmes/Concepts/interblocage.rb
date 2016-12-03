$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

mut1 = Mutex.new
mut2 = Mutex.new

PRuby.pcall\
 -> { mut1.synchronize { mut2.synchronize { puts "Dans thr1" } } },
 -> { sleep 0.1; mut2.synchronize { mut1.synchronize { puts "Dans thr2" } } }

puts "Fin du programme"
