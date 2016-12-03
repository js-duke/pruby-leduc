$LOAD_PATH.unshift('~/pruby/lib')

require 'benchmark'
require 'systeme_planetaire'

def ecrire_acc( nb_planetes, nb_threads, mode, temps, temps_seq )
  acc = temps_seq / temps
  puts "(#{'%3d' % nb_threads}) #{'%-25s' % mode}: #{'%9.3f' % temps}\t#{'%6.2f' % acc}"
end

def mk_planetes( n )
  planetes = []
  n.times do |i|
    planetes << Planete.new( "#{i}",
                             0,
                             rand(10E+15),
                             Vector[rand(10E+10), rand(10E+10)],
                             Vector[rand(10E+10), rand(10E+10)]
                             )
  end
  planetes
end

[10, 20, 40, 80, 160].each do |nb_planetes|
  puts "=== #{nb_planetes} PLANETES ==="
  [2, 4, 8, 16].each do |nb_threads|
    PRuby.nb_threads = nb_threads

    sys0 = SystemePlanetaire.new( *mk_planetes(nb_planetes) )

    modes = SystemePlanetaire::MODES.keys[1..-1]

    sys = sys0.clone
    m = Benchmark.measure { sys.simuler( 10, 100, :sequentiel ) }

    temps_seq = m.real
    ecrire_acc nb_planetes, nb_threads, :sequentiel, temps_seq, temps_seq
    modes.each do |mode|
      sys = sys0.clone
      m = Benchmark.measure { sys.simuler( 10, 100, mode ) }
      ecrire_acc nb_planetes, nb_threads, mode, m.real, temps_seq
    end
    puts
  end
  puts
end

=begin
MACHINE LINUX UQAM: 4 processeurs
=== 10 PLANETES ===
(  2) sequentiel               :     0.067     1.00
(  2) sequentiel_optimise      :     0.054     1.24
(  2) piga                     :     0.080     0.84
(  2) pigc                     :     0.072     0.93
(  2) pst                      :     0.100     0.67

(  4) sequentiel               :     0.062     1.00
(  4) sequentiel_optimise      :     0.058     1.07
(  4) piga                     :     0.061     1.02
(  4) pigc                     :     0.070     0.89
(  4) pst                      :     0.079     0.78

(  8) sequentiel               :     0.054     1.00
(  8) sequentiel_optimise      :     0.051     1.06
(  8) piga                     :     0.066     0.82
(  8) pigc                     :     0.087     0.62
(  8) pst                      :     0.077     0.70

( 16) sequentiel               :     0.052     1.00
( 16) sequentiel_optimise      :     0.048     1.08
( 16) piga                     :     0.075     0.69
( 16) pigc                     :     0.106     0.49
( 16) pst                      :     0.092     0.57


=== 20 PLANETES ===
(  2) sequentiel               :     0.205     1.00
(  2) sequentiel_optimise      :     0.180     1.14
(  2) piga                     :     0.196     1.05
(  2) pigc                     :     0.193     1.06
(  2) pst                      :     0.202     1.01

(  4) sequentiel               :     0.202     1.00
(  4) sequentiel_optimise      :     0.180     1.12
(  4) piga                     :     0.154     1.31
(  4) pigc                     :     0.162     1.25
(  4) pst                      :     0.208     0.97

(  8) sequentiel               :     0.204     1.00
(  8) sequentiel_optimise      :     0.180     1.13
(  8) piga                     :     0.150     1.36
(  8) pigc                     :     0.161     1.27
(  8) pst                      :     0.203     1.00

( 16) sequentiel               :     0.201     1.00
( 16) sequentiel_optimise      :     0.179     1.12
( 16) piga                     :     0.153     1.31
( 16) pigc                     :     0.170     1.18
( 16) pst                      :     0.188     1.07


=== 40 PLANETES ===
(  2) sequentiel               :     0.792     1.00
(  2) sequentiel_optimise      :     0.714     1.11
(  2) piga                     :     0.615     1.29
(  2) pigc                     :     0.542     1.46
(  2) pst                      :     0.603     1.31

(  4) sequentiel               :     0.799     1.00
(  4) sequentiel_optimise      :     0.715     1.12
(  4) piga                     :     0.490     1.63
(  4) pigc                     :     0.436     1.83
(  4) pst                      :     0.485     1.65

(  8) sequentiel               :     0.799     1.00
(  8) sequentiel_optimise      :     0.694     1.15
(  8) piga                     :     0.468     1.71
(  8) pigc                     :     0.446     1.79
(  8) pst                      :     0.514     1.55

( 16) sequentiel               :     0.790     1.00
( 16) sequentiel_optimise      :     0.701     1.13
( 16) piga                     :     0.445     1.78
( 16) pigc                     :     0.453     1.74
( 16) pst                      :     0.507     1.56


=== 80 PLANETES ===
(  2) sequentiel               :     3.165     1.00
(  2) sequentiel_optimise      :     2.765     1.14
(  2) piga                     :     2.361     1.34
(  2) pigc                     :     1.941     1.63
(  2) pst                      :     2.029     1.56

(  4) sequentiel               :     3.175     1.00
(  4) sequentiel_optimise      :     2.762     1.15
(  4) piga                     :     1.859     1.71
(  4) pigc                     :     1.549     2.05
(  4) pst                      :     1.681     1.89

(  8) sequentiel               :     3.175     1.00
(  8) sequentiel_optimise      :     2.764     1.15
(  8) piga                     :     1.686     1.88
(  8) pigc                     :     1.601     1.98
(  8) pst                      :     1.665     1.91

( 16) sequentiel               :     3.173     1.00
( 16) sequentiel_optimise      :     2.765     1.15
( 16) piga                     :     1.633     1.94
( 16) pigc                     :     1.588     2.00
( 16) pst                      :     1.653     1.92


=== 160 PLANETES ===
(  2) sequentiel               :    12.662     1.00
(  2) sequentiel_optimise      :    11.012     1.15
(  2) piga                     :     9.310     1.36
(  2) pigc                     :     7.737     1.64
(  2) pst                      :     7.860     1.61

(  4) sequentiel               :    12.725     1.00
(  4) sequentiel_optimise      :    11.181     1.14
(  4) piga                     :     7.245     1.76
(  4) pigc                     :     6.439     1.98
(  4) pst                      :     7.080     1.80

(  8) sequentiel               :    12.770     1.00
(  8) sequentiel_optimise      :    11.078     1.15
(  8) piga                     :     6.524     1.96
(  8) pigc                     :     6.127     2.08
(  8) pst                      :     6.382     2.00

( 16) sequentiel               :    12.683     1.00
( 16) sequentiel_optimise      :    11.060     1.15
( 16) piga                     :     6.360     1.99
( 16) pigc                     :     6.086     2.08
( 16) pst                      :     6.348     2.00
=end
