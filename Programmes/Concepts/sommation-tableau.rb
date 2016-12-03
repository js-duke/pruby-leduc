$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

a = (1..8).map { |i| 10 * i }

def somme_log( a )
  t0    = a[0] + a[1]
  t1    = a[2] + a[3]
  t2    = a[4] + a[5]
  t3    = a[6] + a[7]
  t4    = t0   + t1
  t5    = t2   + t3
  somme = t4   + t5
end

def somme_lineaire( a )
  t0    = a[0] + a[1]
  t1    =   t0 + a[2]
  t2    =   t1 + a[3]
  t3    =   t2 + a[4]
  t4    =   t3 + a[5]
  t5    =   t4 + a[6]
  somme =   t5 + a[7]
end

def somme_rec( a, i, j )
  if i == j
    a[i]
  else
    m = (i + j) / 2
    s1 = somme_rec( a, i, m )
    s2 = somme_rec( a, m+1, j )
    s1 + s2
  end
end

somme = somme_rec( a, 0, 7 )

puts "OK" if somme == 10 * 8 * 9 / 2
