$LOAD_PATH.unshift('~/pruby/lib')

require 'polynome'
require 'benchmark'

methodes = Polynome::SORTES_DE_MULTIPLICATION.keys[1..-1]

def ecrire_acc( n, produit, temps, temps_seq )
  acc = temps_seq / temps
  puts "(#{'%3d' % n}) #{'%-20s' % produit}: #{'%9.3f' % temps}\t#{'%6.2f' % acc}"
end

[2, 4, 8, 16].each do |nb_threads|
  n = 1000
  PRuby.nb_threads = nb_threads

  #p1 = Polynome.new( *((1..n).map{2**n}.to_a) )
  #p2 = Polynome.new( *((1..n).map{2**n}.to_a) )
  p1 = Polynome.new( *((1..n).to_a) )
  p2 = Polynome.new( *((1..n).to_a) )
  p = nil
  p_ok = nil

  ts = []

  Polynome.sorte_de_multiplication = :seq
  m = Benchmark.measure { p_ok = p1 * p2 }

  Polynome.sorte_de_multiplication = :seq

  temps_seq = m.real
  ecrire_acc nb_threads, :produit_seq, temps_seq, temps_seq
  methodes.each do |methode|
    Polynome.sorte_de_multiplication = methode
    m = Benchmark.measure { p = p1 * p2 }
    DBC.require p == p_ok
    ecrire_acc nb_threads, methode, m.real, temps_seq
  end
  puts
end

=begin
  LINUX MAISON
  n = 1000
  p1 = Polynome.new( *((1..n).to_a) )

(  2) produit_seq         :     4.912    1.00
(  2) pif                 :     2.804    1.75
(  2) piga                :     2.764    1.78
(  2) pigc                :     2.781    1.77
(  2) pigd                :     2.778    1.77

(  4) produit_seq         :     4.874    1.00
(  4) pif                 :     2.331    2.09
(  4) piga                :     2.327    2.09
(  4) pigc                :     1.904    2.56
(  4) pigd                :     1.806    2.70

(  8) produit_seq         :     4.869    1.00
(  8) pif                 :     1.787    2.72
(  8) piga                :     1.762    2.76
(  8) pigc                :     1.502    3.24
(  8) pigd                :     1.471    3.31

( 16) produit_seq         :     4.930    1.00
( 16) pif                 :     1.547    3.19
( 16) piga                :     1.563    3.15
( 16) pigc                :     1.466    3.36
( 16) pigd                :     1.452    3.40
=end


=begin
  LINUX MAISON
  n = 2000
  p1 = Polynome.new( *((1..n).to_a) )

(  2) produit_seq         :    21.878    1.00
(  2) pif                 :    11.825    1.85
(  2) piga                :    12.045    1.82
(  2) pigc                :    12.063    1.81
(  2) pigd                :    12.166    1.80

(  4) produit_seq         :    21.091    1.00
(  4) pif                 :    10.429    2.02
(  4) piga                :     9.559    2.21
(  4) pigc                :     7.586    2.78
(  4) pigd                :     7.258    2.91

(  8) produit_seq         :    20.806    1.00
(  8) pif                 :     7.334    2.84
(  8) piga                :     7.511    2.77
(  8) pigc                :     6.148    3.38
(  8) pigd                :     5.937    3.50

( 16) produit_seq         :    20.607    1.00
( 16) pif                 :     6.149    3.35
( 16) piga                :     6.174    3.34
( 16) pigc                :     5.772    3.57
( 16) pigd                :     5.709    3.61
=end

=begin
  LINUX MAISON
  n = 1000
  p1 = Polynome.new( *((1..n).map {2**n}.to_a) )

(  2) produit_seq         :     9.165    1.00
(  2) pif                 :     5.125    1.79
(  2) piga                :     5.104    1.80
(  2) pigc                :     5.106    1.79
(  2) pigd                :     5.126    1.79

(  4) produit_seq         :     8.998    1.00
(  4) pif                 :     4.415    2.04
(  4) piga                :     3.833    2.35
(  4) pigc                :     3.444    2.61
(  4) pigd                :     3.317    2.71

(  8) produit_seq         :     9.011    1.00
(  8) pif                 :     3.304    2.73
(  8) piga                :     3.025    2.98
(  8) pigc                :     2.729    3.30
(  8) pigd                :     2.661    3.39

( 16) produit_seq         :     8.931    1.00
( 16) pif                 :     2.822    3.16
( 16) piga                :     2.751    3.25
( 16) pigc                :     2.622    3.41
( 16) pigd                :     2.597    3.44
=end

=begin
  MacBook
  n = 2000
  p1 = Polynome.new( *((1..n).to_a) )

(  2) produit_seq         :    13.229     1.00
(  2) pif                 :     9.077     1.46
(  2) piga                :     9.736     1.36
(  2) pigc                :     9.124     1.45
(  2) pigd                :     8.827     1.50

(  4) produit_seq         :    13.041     1.00
(  4) pif                 :     8.701     1.50
(  4) piga                :     8.121     1.61
(  4) pigc                :     7.681     1.70
(  4) pigd                :     7.692     1.70

(  8) produit_seq         :    13.042     1.00
(  8) pif                 :     7.807     1.67
(  8) piga                :     7.835     1.66
(  8) pigc                :     7.826     1.67
(  8) pigd                :     7.714     1.69

( 16) produit_seq         :    13.086     1.00
( 16) pif                 :     7.825     1.67
( 16) piga                :     7.746     1.69
( 16) pigc                :     7.711     1.70
( 16) pigd                :     7.685     1.70
=end

=begin
  malt
  n = 1000
  p1 = Polynome.new( *((1..n).to_a) )

(  2) produit_seq         :     5.864	  1.00
(  2) pif                 :     3.081	  1.90
(  2) piga                :     3.579	  1.64
(  2) pigc                :     2.842	  2.06
(  2) pigd                :     3.150	  1.86

(  4) produit_seq         :     5.317	  1.00
(  4) pif                 :     2.577	  2.06
(  4) piga                :     2.740	  1.94
(  4) pigc                :     2.818	  1.89
(  4) pigd                :     2.094	  2.54

(  8) produit_seq         :     5.316	  1.00
(  8) pif                 :     2.160	  2.46
(  8) piga                :     2.490	  2.13
(  8) pigc                :     2.256	  2.36
(  8) pigd                :     1.591	  3.34

( 16) produit_seq         :     5.231	  1.00
( 16) pif                 :     1.549	  3.38
( 16) piga                :     1.699	  3.08
( 16) pigc                :     1.337	  3.91
( 16) pigd                :     0.963	  5.43
=end
