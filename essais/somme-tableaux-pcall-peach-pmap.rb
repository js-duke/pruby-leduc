$LOAD_PATH.unshift('.', 'lib')

NB_FOIS = 3

require 'benchmark'
require 'pruby'

class Sommes
  def self.somme_tableaux_seq( a, b )
    #puts "somme_tableaux_seq( a, b )"
    DBC.require a.size == b.size, "*** Tailles non identiques pour a et b"

    c = Array.new(a.size)
    (0...a.size).each do |k|
      c[k] = a[k] + b[k]
    end

    c
  end

  def self.somme_tableaux_peach( a, b, nb_threads = PRuby.nb_threads )
    DBC.require a.size == b.size, "*** Tailles non identiques pour a et b"

    c = Array.new(a.size)
    (0...a.size).peach( nb_threads: nb_threads ) do |k|
      c[k] = a[k] + b[k]
    end

    c
  end

  def self.somme_tableaux_peach_dynamique( a, b, nb_threads = PRuby.nb_threads )
    DBC.require a.size == b.size, "*** Tailles non identiques pour a et b"

    c = Array.new(a.size)
    (0...a.size).peach( nb_threads: nb_threads, dynamic: 10 ) do |k|
      c[k] = a[k] + b[k]
    end

    c
  end

  def self.somme_tableaux_pmap( a, b, nb_threads = PRuby.nb_threads )
    DBC.require a.size == b.size, "*** Tailles non identiques pour a et b"

    c = (0...a.size).pmap( nb_threads: nb_threads ) do |k|
      a[k] + b[k]
    end

    c
  end

  def self.somme_tableaux_pmap_dynamique( a, b, nb_threads = PRuby.nb_threads )
    DBC.require a.size == b.size, "*** Tailles non identiques pour a et b"

    c = (0...a.size).pmap( nb_threads: nb_threads, dynamic: 10 ) do |k|
      a[k] + b[k]
    end

    c
  end

  def self.somme_tableaux_pcall_statique( a, b, nb_threads = PRuby.nb_threads )
    #puts "somme_tableaux_pcall_statique( a, b, #{nb_threads} )"

    def self.inf( k, n, nbThreads )
      k * n / nbThreads
    end

    def self.sup( k, n, nbThreads )
      (k+1) * n / nbThreads - 1
    end

    def self.somme_seq( a, b, c, i, j )
      #puts "somme_seq( a, b, c, #{i}, #{j} )"
      (i..j).each do |k|
        c[k] = a[k] + b[k]
      end
    end

    DBC.require a.size == b.size, "*** Tailles non identiques pour a et b"
    DBC.require( a.size % nb_threads == 0,
                 "*** Taille incorrecte: a.size = #{a.size}, " +
                 "nb_threads = #{nb_threads}" )

    c = Array.new(a.size)

    PRuby.pcall\
    (0...nb_threads), lambda { |k|
      self.somme_seq( a,
                      b,
                      c,
                      self.inf(k, a.size, nb_threads),
                      self.sup(k, a.size, nb_threads)
                      )
    }

    c
  end

  def self.somme_tableaux_pcall_cyclique( a, b, nb_threads = PRuby.nb_threads )
    #puts "somme_tableaux_pcall_cyclique( a, b, #{nb_threads} )"
    DBC.require a.size == b.size, "*** Tailles non identiques pour a et b"

    def self.somme_seq_cyclique( a, b, c, num_thread, nb_threads )
      #puts "somme_seq_cyclique( a, b, c, #{num_thread}, #{nb_threads} )"
      num_thread.step( a.size-1, nb_threads ).each do |k|
        c[k] = a[k] + b[k]
      end
    end

    c = Array.new( a.size )

    PRuby.pcall\
    (0...nb_threads), lambda { |num_thread|
      #puts "call to somme_seq_cyclique"
      self.somme_seq_cyclique( a, b, c, num_thread, nb_threads )
    }

    c
  end
end

sommes =  Sommes.methods(false).sort { |x, y| "#{x}" <=> "#{y}" }

sommes.
  reject! { |m| "#{m}" =~ /somme_tableaux_seq/ }

nb_espaces = sommes.map { |v| "#{v}".size }.max + 2

def ecrire_acc( n, somme, temps, temps_seq )
  acc = temps_seq / temps
  puts "(#{'%6d' % n}) #{'%-30s' % somme}: #{'%9.3f' % temps}\t#{'%6.2f' % acc}"
end

def run_it( somme, a, b, nb_threads = PRuby.nb_threads )
  (NB_FOIS-1).times do
    if somme == :somme_tableaux_seq
      Sommes.send somme, a, b
    else
      Sommes.send somme, a, b, nb_threads
    end
  end

  if somme == :somme_tableaux_seq
    Sommes.send somme, a, b
  else
    Sommes.send somme, a, b, nb_threads
  end
end

[8000, 16000, 32000, 64000, 128000, 256000].each do |n|
  a = Array.new(n) { 1 }
  b = Array.new(n) { 1 }
  c = nil

  ts = []
  m = Benchmark.measure { run_it( :somme_tableaux_seq, a, b ) }
  m = Benchmark.measure { c = run_it( :somme_tableaux_seq, a, b ) }
  DBC.ensure c == Sommes.somme_tableaux_seq(a,b), "c = #{c}"
  temps_seq = m.real
  ecrire_acc n, :somme_tableaux_seq, temps_seq, temps_seq
  sommes.each do |somme|
    m = Benchmark.measure { run_it( somme, a, b ) }
    m = Benchmark.measure { c = run_it( somme, a, b ) }
    DBC.ensure c == Sommes.somme_tableaux_seq(a,b), "c = #{c}"
    ecrire_acc n, somme, m.real, temps_seq
  end
  puts
end if false

=begin
(  8000) somme_tableaux_seq            :     0.004   1.00
(  8000) somme_tableaux_pcall_cyclique :     0.002   2.00
(  8000) somme_tableaux_pcall_statique :     0.001   4.00

( 16000) somme_tableaux_seq            :     0.007   1.00
( 16000) somme_tableaux_pcall_cyclique :     0.003   2.33
( 16000) somme_tableaux_pcall_statique :     0.003   2.33

( 32000) somme_tableaux_seq            :     0.012   1.00
( 32000) somme_tableaux_pcall_cyclique :     0.006   2.00
( 32000) somme_tableaux_pcall_statique :     0.012   1.00

( 64000) somme_tableaux_seq            :     0.031   1.00
( 64000) somme_tableaux_pcall_cyclique :     0.016   1.94
( 64000) somme_tableaux_pcall_statique :     0.010   3.10

(128000) somme_tableaux_seq            :     0.052   1.00
(128000) somme_tableaux_pcall_cyclique :     0.020   2.60
(128000) somme_tableaux_pcall_statique :     0.012   4.33

(256000) somme_tableaux_seq            :     0.082   1.00
(256000) somme_tableaux_pcall_cyclique :     0.035   2.34
(256000) somme_tableaux_pcall_statique :     0.033   2.48
=end

n = PRuby.nb_threads * 100000
a = Array.new(n) { 1 }
b = Array.new(n) { 1 }

[1, 2, 4, 8, 16, 32, 64, 128].each do |nb_threads|
  c_seq = nil
  m = Benchmark.measure { run_it( :somme_tableaux_seq, a, b ) }
  m = Benchmark.measure { c_seq = run_it( :somme_tableaux_seq, a, b ) }
  temps_seq = m.real
  ecrire_acc nb_threads, :somme_tableaux_seq, temps_seq, temps_seq
  sommes.each do |somme|
    c_par = nil
    m = Benchmark.measure { run_it( somme, a, b, nb_threads ) }
    m = Benchmark.measure { c_par = run_it( somme, a, b, nb_threads ) }
    ecrire_acc nb_threads, somme, m.real, temps_seq
    DBC.assert c_seq == c_par, "Resultat par != seq"
  end
  puts
end

=begin
(     1) somme_tableaux_seq            :     0.314   1.00
(     1) somme_tableaux_pcall_cyclique :     0.326   0.96
(     1) somme_tableaux_pcall_statique :     0.313   1.00

(     2) somme_tableaux_seq            :     0.308   1.00
(     2) somme_tableaux_pcall_cyclique :     0.198   1.56
(     2) somme_tableaux_pcall_statique :     0.202   1.52

(     4) somme_tableaux_seq            :     0.292   1.00
(     4) somme_tableaux_pcall_cyclique :     0.122   2.39
(     4) somme_tableaux_pcall_statique :     0.119   2.45

(     8) somme_tableaux_seq            :     0.291   1.00
(     8) somme_tableaux_pcall_cyclique :     0.100   2.91
(     8) somme_tableaux_pcall_statique :     0.097   3.00

(    16) somme_tableaux_seq            :     0.290   1.00
(    16) somme_tableaux_pcall_cyclique :     0.110   2.64
(    16) somme_tableaux_pcall_statique :     0.107   2.71

(    32) somme_tableaux_seq            :     0.298   1.00
(    32) somme_tableaux_pcall_cyclique :     0.099   3.01
(    32) somme_tableaux_pcall_statique :     0.086   3.47

(    64) somme_tableaux_seq            :     0.240   1.00
(    64) somme_tableaux_pcall_cyclique :     0.085   2.82
(    64) somme_tableaux_pcall_statique :     0.083   2.89

(   128) somme_tableaux_seq            :     0.242   1.00
(   128) somme_tableaux_pcall_cyclique :     0.085   2.85
(   128) somme_tableaux_pcall_statique :     0.081   2.99
=end
