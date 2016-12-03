$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'
require 'matrice'

#@@@/distance_rec/distance/
def cout_subst( c1, c2 )
  c1 == c2 ? 0 : 1
end

def distance_rec( ch1, ch2 )
  # Cas de base
  return ch2.size if ch1.size == 0
  return ch1.size if ch2.size == 0

  # Cas recursifs
  avec_insertion =
    distance_rec( ch1, ch2[0..-2] ) + 1

  avec_suppression =
    distance_rec( ch1[0..-2], ch2 ) + 1

  avec_substitution =
    distance_rec( ch1[0..-2], ch2[0..-2] ) +
                  cout_subst(ch1[-1], ch2[-1])

  [avec_insertion, avec_suppression, avec_substitution].min
end
#@@@

$level = 0
def distance_rec_debug( ch1, ch2 )
  print "  " * $level if $debug
  print "distance_rec( #{ch1.inspect}, #{ch2.inspect} )" if $debug
  ( r = ch2.size; puts " = #{r}"; return r ) if ch1.size == 0
  ( r = ch1.size; puts " = #{r}"; return r ) if ch2.size == 0
  puts

  $level += 1
  d_insertion =
    distance_rec_debug( ch1, ch2[0..-2] ) + 1
  d_suppression =
    distance_rec_debug( ch1[0..-2], ch2 ) + 1
  d_substitution =
    distance_rec_debug( ch1[0..-2], ch2[0..-2] ) + cout_subst(ch1[-1], ch2[-1])
  $level -= 1

  r = [d_insertion, d_suppression, d_substitution].min
  print "  " * $level if $debug
  puts "distance_rec( #{ch1.inspect}, #{ch2.inspect} ) => #{r}" if $debug

  r
end
#@@@

#@@@/distance_seq/distance/
def distance_seq( ch1, ch2 )
  n1 = ch1.size
  n2 = ch2.size
  d = Matrice.new( n1+1, n2+1 )

  # Cas de base (couts unitaires).
  d[0,0] = 0
  (1..n1).each do |i|
    d[i, 0] = i
  end
  (1..n2).each do |j|
    d[0, j] = j
  end

  # Cas recursifs.
  ((1..n1)*(1..n2)).each do |i, j|
    d[i, j] = [ d[i-1, j] + 1,
                d[i, j-1] + 1,
                d[i-1, j-1] + cout_subst( ch1[i], ch2[j] )
              ].min
  end

  d[n1, n2]
end
#@@@

#@@@/distance_peach/distance/
def distance_peach( ch1, ch2 )
  n1 = ch1.size
  n2 = ch2.size
  d = Matrice.new( n1+1, n2+1 )

  # Cas de base (couts unitaires).
  d[0,0] = 0
  (1..n1).peach do |i|
    d[i, 0] = i
  end
  (1..n2).peach do |j|
    d[0, j] = j
  end

  # Cas recursifs... selon les diagonales (wavefront).
  (2..n1+n2).each do |k|
   ((1..n1)*(1..n2)).select{|i, j| i+j == k}.peach do |i, j|
     d[i, j] = [ d[i-1, j] + 1,
                 d[i, j-1] + 1,
                 d[i-1, j-1] + cout_subst( ch1[i], ch2[j] )
               ].min
    end
  end

  d[n1, n2]
end
#@@@
