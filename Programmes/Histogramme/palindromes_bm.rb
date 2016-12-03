$LOAD_PATH.unshift('~/pruby/lib')

require 'palindromes'
require 'benchmark'

def ecrire_acc( n, method, temps, temps_seq )
  method =~ /^trouver_palindromes_(.*)$/
  method = $1
  acc = temps_seq / temps
  puts "(#{'%3d' % n}) #{'%-25s' % method}: #{'%9.3f' % temps}\t#{'%6.2f' % acc}"
end

[2, 4, 8, 16, 32, 64].each do |nb_threads|
  PRuby.nb_threads = nb_threads

  mots = IO.readlines( "/usr/share/dict/words" )
  #mots = mots.take(100)
  mots.map!(&:chomp)


  methodes = [:trouver_palindromes_par_donnees_sans_mutex, :trouver_palindromes_par_donnees, :trouver_palindromes_par_resultat]
  methodes = [:trouver_palindromes_par_donnees_sans_mutex, :trouver_palindromes_par_donnees]

  pals_seq = nil
  m = Benchmark.measure { pals_seq = trouver_palindromes_seq( mots, 26 ) }

  temps_seq = m.real
  ecrire_acc nb_threads, :trouver_palindromes_seq, temps_seq, temps_seq
  methodes.each do |methode|
    pals = nil
    m = Benchmark.measure { pals = send methode, mots, 26 }
    if pals.map{ |p| p.sort } != pals_seq.map { |p| p.sort }
      puts "*** Erreur dans #{methode}"
      puts "pals = #{pals}"
      puts "pals_seq = #{pals_seq}"
    end

    ecrire_acc nb_threads, methode, m.real, temps_seq
  end
  puts
end

=begin

Resultats sur Linux maison: La version de parallelisme de resultat est
vraiment plus mauvaise.  De plus, la version sans mutex produit malgre
tout (?) le bon resultat (!?).

(  2) seq                      :     0.868     1.00
(  2) par_donnees_sans_mutex   :     0.559     1.55
(  2) par_donnees              :     0.556     1.56
(  2) par_resultat             :     8.947     0.10

(  4) seq                      :     0.572     1.00
(  4) par_donnees_sans_mutex   :     0.484     1.18
(  4) par_donnees              :     0.523     1.09
(  4) par_resultat             :     6.811     0.08

(  8) seq                      :     0.467     1.00
(  8) par_donnees_sans_mutex   :     0.373     1.25
(  8) par_donnees              :     0.354     1.32
(  8) par_resultat             :     5.559     0.08

( 16) seq                      :     0.463     1.00
( 16) par_donnees_sans_mutex   :     0.310     1.49
( 16) par_donnees              :     0.329     1.41
( 16) par_resultat             :     4.860     0.10
=end


=begin

Autre execution sur Linux maison, avec plus de threads, mais sans
parallelisme de resultat car trop mauvais. Le plus bizarre est que la
version sans_mutex produit aussi le bon resultat est n'est meme pas
plus rapide!

(  2) seq                      :     0.488     1.00
(  2) par_donnees_sans_mutex   :     0.646     0.76
(  2) par_donnees              :     0.655     0.75

(  4) seq                      :     0.541     1.00
(  4) par_donnees_sans_mutex   :     0.504     1.07
(  4) par_donnees              :     0.422     1.28

(  8) seq                      :     0.789     1.00
(  8) par_donnees_sans_mutex   :     0.334     2.36
(  8) par_donnees              :     0.357     2.21

( 16) seq                      :     0.510     1.00
( 16) par_donnees_sans_mutex   :     0.389     1.31
( 16) par_donnees              :     0.332     1.54

( 32) seq                      :     0.716     1.00
( 32) par_donnees_sans_mutex   :     0.314     2.28
( 32) par_donnees              :     0.305     2.35

( 64) seq                      :     0.489     1.00
( 64) par_donnees_sans_mutex   :     0.341     1.43
( 64) par_donnees              :     0.294     1.66
=end
