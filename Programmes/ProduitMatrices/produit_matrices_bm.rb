$LOAD_PATH.unshift('~/pruby/lib')

require 'benchmark'
require 'matrice'
require 'pruby'
require_relative 'produit_matrices'


class Produits
  def self.prod_scalaire( a, i, b, j )
    r = 0
    (0...a.nb_colonnes).each do |k|
      r += a[i, k] * b[k, j]
    end
    r
  end

  def self.produit_seq( a, b )
    c = Matrice.new( a.nb_lignes, b.nb_colonnes )

    (0...c.nb_lignes).each do |i|
      (0...c.nb_colonnes).each do |j|
        c[i, j] = prod_scalaire( a, i, b, j )
      end
    end

    c
  end

  def self.produit_peach_each( a, b )
    DBC.require a.nb_colonnes == b.nb_lignes

    c = Matrice.new( a.nb_lignes, b.nb_colonnes )

    (0...c.nb_lignes).peach(static: true) do |i|
      (0...c.nb_colonnes).each do |j|
        c[i, j] = prod_scalaire( a, i, b, j )
      end
    end

    c
  end

  def self.produit_peach_peach( a, b )
    DBC.require a.nb_colonnes == b.nb_lignes

    c = Matrice.new( a.nb_lignes, b.nb_colonnes )

    (0...c.nb_lignes).peach(static: true) do |i|
      (0...c.nb_colonnes).peach(static: true) do |j|
        c[i, j] = prod_scalaire( a, i, b, j )
      end
    end

    c
  end

  def self.produit_pcall( a, b )
    DBC.require a.nb_colonnes == b.nb_lignes

    c = Matrice.new( a.nb_lignes, b.nb_colonnes )

    PRuby.pcall\
    0...c.nb_lignes, lambda { |i|
      PRuby.pcall\
      0...c.nb_colonnes, lambda { |j|
        c[i, j] = prod_scalaire( a, i, b, j )
      }
    }

    c
  end

  def self.produit_range2d( a, b )
    DBC.require a.nb_colonnes == b.nb_lignes

    c = Matrice.new( a.nb_lignes, b.nb_colonnes )

    ((0...c.nb_lignes)*(0...c.nb_colonnes)).peach do |i, j|
      c[i, j] = prod_scalaire( a, i, b, j )
    end

    c
  end
end

produits =  Produits.methods(false).sort { |x, y| "#{x}" <=> "#{y}" }
produits.
  reject! { |m| "#{m}" !~ /produit/ }.
  reject! { |m| "#{m}" =~ /produit_seq/ }

nb_espaces = produits.map { |v| "#{v}".size }.max + 2

def ecrire_acc( n, produit, temps, temps_seq )
  acc = temps_seq / temps
  puts "(#{'%3d' % n}) #{'%-20s' % produit}: #{'%9.3f' % temps}\t#{'%6.2f' % acc}"
end

#####################################

Matrice.no_bound_check = true

PRuby.nb_threads = 4  # Pour MALT: SINON = 16 et cela semble trop!!

[25, 50, 100, 200].each do |n|
  a = Matrice.new(n) { 1 }
  b = Matrice.new(n) { 1 }
  c = nil

  ts = []
  m = Benchmark.measure { Produits.send :produit_seq, a, b }
  temps_seq = m.real
  ecrire_acc n, :produit_seq, temps_seq, temps_seq
  produits.each do |produit|
    m = Benchmark.measure { c = Produits.send produit, a, b }
    DBC.require c == a*b
    ecrire_acc n, produit, m.real, temps_seq
  end
  puts
end if false

[1, 2, 4, 8, 16].each do |nb_threads|
  n = 64
  PRuby.nb_threads = nb_threads

  a = Matrice.new(n) { 2**128 }
  b = Matrice.new(n) { 2**128 }
  c = nil

  ts = []

  #GC.start
  m = Benchmark.measure { Produits.send :produit_seq, a, b }
  temps_seq = m.real
  ecrire_acc nb_threads, :produit_seq, temps_seq, temps_seq
  produits.each do |produit|
    #GC.start
    m = Benchmark.measure { c = Produits.send produit, a, b }
    DBC.require c == a*b
    ecrire_acc nb_threads, produit, m.real, temps_seq
  end
  puts
end


=begin
LINUX UQAM (avec produit_range2d) (n = 64), avec
divers nombres de threads
=================================================
(  1) produit_seq         :     6.828    1.00
(  1) produit_pcall       :     6.735    1.01
(  1) produit_peach_each  :     6.829    1.00
(  1) produit_peach_peach :     6.882    0.99
(  1) produit_range2d     :     6.842    1.00

(  2) produit_seq         :     6.792    1.00
(  2) produit_pcall       :     6.570    1.03
(  2) produit_peach_each  :     8.826    0.77
(  2) produit_peach_peach :     6.077    1.12
(  2) produit_range2d     :     8.331    0.82

(  4) produit_seq         :     6.792    1.00
(  4) produit_pcall       :     6.349    1.07
(  4) produit_peach_each  :     5.913    1.15
(  4) produit_peach_peach :     6.728    1.01
(  4) produit_range2d     :     5.897    1.15

(  8) produit_seq         :     6.800    1.00
(  8) produit_pcall       :     6.371    1.07
(  8) produit_peach_each  :     5.981    1.14
(  8) produit_peach_peach :     6.633    1.03
(  8) produit_range2d     :     6.048    1.12

( 16) produit_seq         :     6.996    1.00
( 16) produit_pcall       :     6.144    1.14
( 16) produit_peach_each  :     7.216    0.97
( 16) produit_peach_peach :     6.732    1.04
( 16) produit_range2d     :     6.214    1.13
=end

=begin
LINUX maison (avec produit_range2d) (n = 64), avec
divers nombres de threads... et avec GC.start effectue
juste *avant* l'appel a l'operation
(  1) produit_seq         :     4.019    1.00
(  1) produit_pcall       :     3.259    1.23
(  1) produit_peach_each  :     3.883    1.04
(  1) produit_peach_peach :     4.185    0.96
(  1) produit_range2d     :     3.865    1.04

(  2) produit_seq         :     3.938    1.00
(  2) produit_pcall       :     3.157    1.25
(  2) produit_peach_each  :     3.505    1.12
(  2) produit_peach_peach :     2.603    1.51
(  2) produit_range2d     :     3.512    1.12

(  4) produit_seq         :     4.160    1.00
(  4) produit_pcall       :     3.308    1.26
(  4) produit_peach_each  :     2.550    1.63
(  4) produit_peach_peach :     2.929    1.42
(  4) produit_range2d     :     2.995    1.39

(  8) produit_seq         :     4.018    1.00
(  8) produit_pcall       :     3.264    1.23
(  8) produit_peach_each  :     2.993    1.34
(  8) produit_peach_peach :     3.255    1.23
(  8) produit_range2d     :     3.017    1.33

( 16) produit_seq         :     5.737    1.00
( 16) produit_pcall       :     3.275    1.75
( 16) produit_peach_each  :     3.101    1.85
( 16) produit_peach_peach :     3.195    1.80
( 16) produit_range2d     :     3.160    1.82
=end

=begin
LINUX maison (avec produit_range2d) (n = 64), avec
divers nombres de threads
=================================================
(  1) produit_seq         :     3.996    1.00
(  1) produit_pcall       :     3.239    1.23
(  1) produit_peach_each  :     3.920    1.02
(  1) produit_peach_peach :     4.048    0.99
(  1) produit_range2d     :     3.924    1.02

(  2) produit_seq         :     3.929    1.00
(  2) produit_pcall       :     2.966    1.32
(  2) produit_peach_each  :     3.795    1.04
(  2) produit_peach_peach :     2.368    1.66
(  2) produit_range2d     :     3.651    1.08

(  4) produit_seq         :     3.939    1.00
(  4) produit_pcall       :     2.727    1.44
(  4) produit_peach_each  :     2.294    1.72
(  4) produit_peach_peach :     2.940    1.34
(  4) produit_range2d     :     2.279    1.73

(  8) produit_seq         :     3.970    1.00
(  8) produit_pcall       :     2.936    1.35
(  8) produit_peach_each  :     2.728    1.46
(  8) produit_peach_peach :     2.956    1.34
(  8) produit_range2d     :     2.732    1.45

( 16) produit_seq         :     3.951    1.00
( 16) produit_pcall       :     2.958    1.34
( 16) produit_peach_each  :     2.627    1.50
( 16) produit_peach_peach :     3.031    1.30
( 16) produit_range2d     :     2.861    1.38
=end

=begin
LINUX UQAM (avec produit_range2d) (4 processeurs)
=================================================
( 25) produit_seq         :     0.396    1.00
( 25) produit_pcall       :     0.424    0.93
( 25) produit_peach_each  :     0.367    1.08
( 25) produit_peach_peach :     0.441    0.90
( 25) produit_range2d     :     0.358    1.11

( 50) produit_seq         :     3.256    1.00
( 50) produit_pcall       :     3.157    1.03
( 50) produit_peach_each  :     2.740    1.19
( 50) produit_peach_peach :     3.159    1.03
( 50) produit_range2d     :     2.746    1.19

(100) produit_seq         :    25.212    1.00
(100) produit_pcall       :    25.004    1.01
(100) produit_peach_each  :    24.256    1.04
(100) produit_peach_peach :    25.165    1.00
(100) produit_range2d     :    22.962    1.10

(200) produit_seq         :   201.431    1.00
(200) produit_pcall       :   195.231    1.03
(200) produit_peach_each  :   181.132    1.11
(200) produit_peach_peach :   196.873    1.02
(200) produit_range2d     :   181.110    1.11
=end

=begin
MA MACHINE LINUX (4 processeurs)
================================
( 25) produit_seq         :     0.249    1.00
( 25) produit_pcall       :     0.269    0.93
( 25) produit_peach_each  :     0.202    1.23
( 25) produit_peach_peach :     0.230    1.08

( 50) produit_seq         :     1.987    1.00
( 50) produit_pcall       :     1.744    1.14
( 50) produit_peach_each  :     1.502    1.32
( 50) produit_peach_peach :     1.527    1.30

(100) produit_seq         :    15.769    1.00
(100) produit_pcall       :    13.448    1.17
(100) produit_peach_each  :    13.025    1.21
(100) produit_peach_peach :    12.917    1.22

(200) produit_seq         :   126.653    1.00
(200) produit_pcall       :   103.614    1.22
(200) produit_peach_each  :    99.520    1.27
(200) produit_peach_peach :   102.935    1.23
=end

=begin
MALT (avec 4 threads)
======================
( 25) produit_seq         :     0.304  1.00
( 25) produit_pcall       :     0.695  0.44
( 25) produit_peach_each  :     0.463  0.66
( 25) produit_peach_peach :     0.733  0.41

( 50) produit_seq         :     2.454  1.00
( 50) produit_pcall       :     4.891  0.50
( 50) produit_peach_each  :     2.467  0.99
( 50) produit_peach_peach :     4.026  0.61

(100) produit_seq         :    18.677  1.00
(100) produit_pcall       :    37.354  0.50
(100) produit_peach_each  :    15.303  1.22
(100) produit_peach_peach :    37.816  0.49

(200) produit_seq         :   148.267  1.00
(200) produit_pcall       :   304.280  0.49
(200) produit_peach_each  :   120.652  1.23
(200) produit_peach_peach :   302.477  0.49
=end
