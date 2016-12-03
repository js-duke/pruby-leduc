$LOAD_PATH.unshift('.', 'lib')

require 'benchmark'
require 'matrice'

def inc( m )
  m.nb_lignes.times do |i|
    m.nb_colonnes.times do |j|
      m[i,j] += 1
    end
  end
end

nb_espaces = 30

[50, 100, 200, 400, 800].each do |nb|
  Benchmark.bm(nb_espaces) do |bm|
    m1 = Matrice.new( nb )                { |i,j| i * j }
    m2 = Matrice.new( nb, nb, nil, true ) { |i,j| i * j }
    
    bm.report( "Version ordinaire: nb = #{nb}" ) do
      inc m1
    end
    
    bm.report( "Version lineaire:  nb = #{nb}" ) do
      inc m2
    end
  end
end

=begin
                                     user     system      total        real
Version ordinaire: nb = 50       0.050000   0.000000   0.050000 (  0.026000)
Version lineaire:  nb = 50       0.000000   0.000000   0.000000 (  0.002000)
                                     user     system      total        real
Version ordinaire: nb = 100      0.070000   0.000000   0.070000 (  0.067000)
Version lineaire:  nb = 100      0.010000   0.000000   0.010000 (  0.010000)
                                     user     system      total        real
Version ordinaire: nb = 200      0.300000   0.000000   0.300000 (  0.277000)
Version lineaire:  nb = 200      0.050000   0.000000   0.050000 (  0.043000)
                                     user     system      total        real
Version ordinaire: nb = 400      1.250000   0.010000   1.260000 (  1.119000)
Version lineaire:  nb = 400      0.210000   0.000000   0.210000 (  0.165000)
                                     user     system      total        real
Version ordinaire: nb = 800     11.170000   0.040000  11.210000 (  5.210000)
Version lineaire:  nb = 800      1.730000   0.000000   1.730000 (  0.767000)
=end
