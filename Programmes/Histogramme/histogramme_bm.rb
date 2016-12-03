$LOAD_PATH.unshift('~/pruby/lib')

require 'histogramme'
require 'benchmark'

def ecrire_acc( n, method, temps, temps_seq )
  method =~ /^histogramme_(.*)$/
  method = $1
  acc = temps_seq / temps
  puts "(#{'%3d' % n}) #{'%-25s' % method}: #{'%9.3f' % temps}\t#{'%6.2f' % acc}"
end

[2, 4, 8, 16, 32, 64].each do |nb_threads|
  PRuby.nb_threads = nb_threads

  mots = IO.readlines( "/usr/share/dict/words" )
  #mots = mots.take(1000)
  mots.map!(&:chomp)


  methodes = [:histogramme_par_donnees_sans_mutex, :histogramme_par_donnees_avec_mutex, :histogramme_par_donnees, :histogramme_par_resultat]

  methodes = methodes[0..-2]

  histo_seq = nil
  GC.start
  m = Benchmark.measure { histo_seq = histogramme_seq( mots, 26 ) }

  temps_seq = m.real
  ecrire_acc nb_threads, :histogramme_seq, temps_seq, temps_seq
  methodes.each do |methode|
    histo = nil
    GC.start
    m = Benchmark.measure { histo = send methode, mots, 26 }
    if false && histo != histo_seq
      puts "*** Erreur dans #{methode}"
      puts "histo = #{histo}"
      puts "histo_seq = #{histo_seq}"
    end

    ecrire_acc nb_threads, methode, m.real, temps_seq
  end
  puts
end

=begin
Resultats sur machine Linux Maison (NB_FOIS = 20)
---------------------------------------------------
(  2) seq                      :     3.017     1.00
(  2) par_donnees_sans_mutex   :     2.078     1.45
(  2) par_donnees_avec_mutex   :     2.741     1.10
(  2) par_donnees              :     2.215     1.36

(  4) seq                      :     3.400     1.00
(  4) par_donnees_sans_mutex   :     1.708     1.99
(  4) par_donnees_avec_mutex   :     1.484     2.29
(  4) par_donnees              :     1.318     2.58

(  8) seq                      :     3.429     1.00
(  8) par_donnees_sans_mutex   :     1.053     3.26
(  8) par_donnees_avec_mutex   :     1.252     2.74
(  8) par_donnees              :     1.121     3.06

( 16) seq                      :     3.413     1.00
( 16) par_donnees_sans_mutex   :     1.383     2.47
( 16) par_donnees_avec_mutex   :     1.376     2.48
( 16) par_donnees              :     1.118     3.05

( 32) seq                      :     3.452     1.00
( 32) par_donnees_sans_mutex   :     1.007     3.43
( 32) par_donnees_avec_mutex   :     1.328     2.60
( 32) par_donnees              :     1.065     3.24

( 64) seq                      :     3.427     1.00
( 64) par_donnees_sans_mutex   :     1.300     2.64
( 64) par_donnees_avec_mutex   :     1.331     2.57
( 64) par_donnees              :     1.030     3.33
=end
