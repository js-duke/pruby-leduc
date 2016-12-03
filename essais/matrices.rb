$LOAD_PATH.unshift('.', 'lib')

require 'benchmark'
require 'dbc'

class Matrice
  def to_s
    (0...@n).each do |i|
      (0...@m).each do |j|
        x = get(i, j)
        print (x ? "#{x} " : "? ")
      end
      puts
    end
  end

  def init
    (0...@n).each do |i|
      (0...@n).each do |j|
        set(i, j, yield(i, j) )
      end
    end
    self
  end

  def somme_par_ligne
    somme = 0
    (0...@n).each do |i|
      (0...@m).each do |j|
        somme += get(i, j)
      end
    end
    somme
  end

  def somme_par_colonne
    somme = 0
    (0...@n).each do |i|
      (0...@m).each do |j|
        somme += get(i, j)
      end
    end
    somme
  end
end

class MatriceVV < Matrice
  def initialize( n, m = n )
    @n, @m = n, m
    @lignes = Array.new( n )
    @lignes.map! { Array.new(m) }
  end

  def get( i, j )
    @lignes[i][j]
  end

  def set( i, j, x )
    @lignes[i][j] = x
  end
end

class MatriceV < Matrice
  def initialize( n, m = n )
    @n, @m = n, m
    @a = Array.new( n * m )
  end

  def get( i, j )
    p = @m * i + j
    @a[p]
  end

  def set( i, j, x )
    p = @m * i + j
    @a[p] = x
  end

  def to_s
    (0...@n).each do |i|
      (0...@m).each do |j|
        x = get(i, j)
        print (x ? "#{x} " : "? ")
      end
      puts
    end
  end
end


m1 = MatriceVV.new(10).init { |i, _j| i }


(0...10).each do |i|
  (0...10).each do |j|
    DBC.assert m1.get(i, j) == i
  end
end

m2 = MatriceV.new(10).init { |i, _j| i }

(0...10).each do |i|
  (0...10).each do |j|
    DBC.assert m2.get(i, j) == i
  end
end

s1 = m1.somme_par_ligne
s2 = m2.somme_par_ligne

DBC.assert s1 == 450
DBC.assert s2 == 450



nb_espaces = 30
N = 2000
NB_FOIS = 5

def run_it( nb_fois )
  nb_fois.times do
    yield
  end
end

Benchmark.bmbm(nb_espaces) do |bm|
  m1 = MatriceV.new( N ).init { |i, j| 1.0 * i * j }
  m2 = MatriceVV.new( N ).init { |i, j| 1.0 * i * j }

  bm.report( "MatriceV  : somme_par_ligne" ) do
    run_it(NB_FOIS) { m1.somme_par_ligne }
  end

  bm.report( "MatriceVV : somme_par_ligne" ) do
    run_it(NB_FOIS) { m2.somme_par_ligne }
  end

  bm.report( "MatriceV  : somme_par_colonne" ) do
    run_it(NB_FOIS) { m1.somme_par_colonne }
  end

  bm.report( "MatriceVV : somme_par_colonne" ) do
    run_it(NB_FOIS) { m2.somme_par_colonne }
  end

end



puts "OK"

=begin
#
# Resultats (inattendu!!!!)
#

$ ruby essais/matrices.rb

Rehearsal ------------------------------------------------------------------
MatriceV  : somme_par_ligne    142.410000   0.660000 143.070000 ( 42.658000)
MatriceVV : somme_par_ligne     84.010000   0.290000  84.300000 ( 24.625000)
MatriceV  : somme_par_colonne  144.830000   0.440000 145.270000 ( 40.717000)
MatriceVV : somme_par_colonne   84.720000   0.350000  85.070000 ( 28.610000)
------------------------------------------------------- total: 457.710000sec

user     system      total        real
MatriceV  : somme_par_ligne    146.340000   0.540000 146.880000 ( 45.565000)  4
MatriceVV : somme_par_ligne     78.480000   0.210000  78.690000 ( 24.169000)  2
MatriceV  : somme_par_colonne  140.450000   0.380000 140.830000 ( 39.399000)  3
MatriceVV : somme_par_colonne   83.470000   0.230000  83.700000 ( 23.817000)  1
=end
