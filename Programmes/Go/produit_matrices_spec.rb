$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'produit_matrices'

def matrice( n )
  m = Array.new(n)
  (0...n).each do |i|
    m[i] = Array.new(n)
    (0...n).each do |j|
      m[i][j] = yield(i,j)
    end
  end

  m
end

describe ProduitMatrices do
  it "execute avec 5 travailleurs pour matrice 10 X 10 version go" do
    n = 120
    nb_travailleurs = 6
    a = matrice(n) { |i, j| 2 }
    b = matrice(n) { |i, j| 3 }
    c_attendu = matrice(n) { |i,j| 2*3*n }

    c = ProduitMatrices.run( a, b, nb_travailleurs )
    c.must_equal c_attendu
  end
end
