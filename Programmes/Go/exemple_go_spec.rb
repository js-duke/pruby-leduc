$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require 'pruby'

describe "Processus style go" do
  it "traite un petit pipeline avec la syntaxe style go" do
    p1 = lambda do |cin, cout|
      n = cin.get
      (1..n).each { |i| cout << i }
      cout.close
    end

    p2 = lambda do |cin, cout|
      cin.each { |v| cout << 10 * v }
      cout.close
    end

    p3 = lambda do |cin, cout|
      r = 0
      cin.each { |v| r += v }
      cout << r
      cout.close
    end

    c1, c2, c3, c4 = Array.new(4) { PRuby::Channel.new }
    p1.go( c1, c2 )
    p2.go( c2, c3 )
    p3.go( c3, c4 )

    # Transfert de la donnee initiale et reception du resultat.
    # Transfert de la donnee initiale,
    # pour amorcer le flux de donnees
    c1 << 10

    # Reception du resultat.
    c4.get.must_equal 550
  end
end
