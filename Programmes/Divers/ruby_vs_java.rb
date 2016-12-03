$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

def pfoo( num_thread, a1, a2 )
  puts 'call pfoo'
  nil
end

def ffoo( num_thread, a1, a2 )
  puts 'call ffoo'
  num_thread
end

def f1( x )
  puts 'call f1'
  x
end

def f2( x )
  puts 'call f1'
  x
end



nb_threads = 3


=begin
PRuby.pcall( (0...nb_threads),
             lambda { |k| pfoo( k, f1(k), f2(k) ) } )

(0...nb_threads).each do |k|
  PRuby.future { pfoo( k, f1(k), f2(k) ) }
end
=end

fs = (0...nb_threads).map do |k|
  PRuby.future { ffoo( k, f1(k), f2(k) ) }
end

rs = fs.map(&:value)

r = Array.new( nb_threads )
PRuby.pcall( (0...nb_threads),
             lambda { |k| r[k] = f2(f1(k)) + f1(k) }
             )

r = Array.new( nb_threads )
r.peach_index( static: 1, nb_threads: nb_threads ) do |k|
  r[k] = f2(f1(k)) + f1(k)
end
=begin
=end
