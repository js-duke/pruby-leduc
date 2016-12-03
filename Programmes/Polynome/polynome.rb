$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

class Polynome
  SORTES_DE_MULTIPLICATION = {
    :seq  => :fois_seq,
    :pif  => :fois_pif,
    :piga => :fois_piga,
    :pigc => :fois_pigc,
    :pigd => :fois_pigd
  }

  class << self
    attr_accessor :sorte_de_multiplication
  end

  def initialize( *coeffs )
    while coeffs.size > 1 && coeffs.last == 0
      coeffs.pop
    end
    @coeffs = *coeffs
  end

  def taille
    @coeffs.size
  end

  def []( i )
    DBC.require 0 <= i && i < taille, "*** i = #{i} vs. taille = #{taille}"
    @coeffs[i]
  end

  def ==( autre )
    return autre == self if taille > autre.taille
    DBC.assert taille <= autre.taille, "*** taille > autre.taille"

    return false unless (0...taille).all? { |i| self[i] == autre[i] }

    return false unless (taille...autre.taille).all? { |i| autre[i] == 0 }

    true
  end

  def *( autre )
    sorte_mul = Polynome.sorte_de_multiplication || :seq
    send Polynome::SORTES_DE_MULTIPLICATION[sorte_mul], autre
  end

  def coefficient_( k, p1, p2 )
    n1 = p1.taille
    n2 = p2.taille

    c = 0
    ((0...n1) * (0...n2)).select { |i, j| i+j == k }.each do |i, j|
      # La somme des exposants des coefficients
      # de p1 (i-1) et p2 (i-1) est egale a l'exposant (k-1) du coefficent
      # du resultat a calculer: on fait le produit et on cumule.
      c += p1[i] * p2[j]
    end

    c
  end

  def coefficient( k, p1, p2 )
    exp_min = [ 0, k - p2.taille + 1 ].max
    exp_max = [ k, p1.taille - 1 ].min

    DBC.assert( exp_min <= exp_max,
                "exp_min (#{exp_min}) > exp_max (#{exp_max})??" )

    (exp_min..exp_max).
      reduce(0) { |somme, i| somme + p1[i] * p2[k-i] }
  end

  def fois_seq( autre )
    n = taille + autre.taille - 1

    coeffs = (0...n).map { |k| coefficient( k, self, autre ) }

    Polynome.new( *coeffs )
  end

  def fois_pif( autre )
    n = taille + autre.taille - 1

    coeffs = (0...n).pmap { |k| coefficient( k, self, autre ) }

    Polynome.new( *coeffs )
  end

  def fois_piga( autre )
    n = taille + autre.taille - 1

    coeffs = (0...n).pmap(static: true) { |k| coefficient( k, self, autre ) }

    Polynome.new( *coeffs )
  end

  def fois_pigc( autre )
    n = taille + autre.taille - 1

    coeffs = (0...n).pmap(static: 1) { |k| coefficient( k, self, autre ) }

    Polynome.new( *coeffs )
  end

  def fois_pigd( autre )
    n = taille + autre.taille - 1

    coeffs = (0...n).pmap(dynamic: 5) { |k| coefficient( k, self, autre ) }

    Polynome.new( *coeffs )
  end

  def +( autre )
    return autre + self if taille > autre.taille

    DBC.assert taille <= autre.taille, "*** taille > autre.taille!?"

    coeffs = (0...autre.taille).map do |k|
      (k < taille ? self[k] : 0) + autre[k]
    end

    Polynome.new( *coeffs )
  end

  def zero?
    taille == 1 && self[0] == 0
  end

  def to_s
    return "0" if zero?

    coeffs = []
    (taille-1).step(0, -1) do |k|
      next if self[k] == 0       # On saute les 0
      coeffs << "#{self[k]}"
      coeffs.last << "*x" if k >= 1
      coeffs.last << "^#{k}" if k > 1
    end
    coeffs.join("+")
  end
end
