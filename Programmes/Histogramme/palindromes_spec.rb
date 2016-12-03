$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'palindromes'

describe "palindromes" do
  before do
    @nb_buckets = 5
    @mots = ["abc", "abba", "kayak", "foo", "foof", "aA", "aaa", "b", "ddDDd"]

    @pals = Array.new(@nb_buckets){ [] }

    @pals = [
             ["abba", "kayak", "foof", "aA", "aaa"],
             ["b"],
             [],
             ["ddDDd"],
             []
            ]
  end

  it "produit le resultat correct de facon sequentielle" do
    pals = trouver_palindromes_seq( @mots, @nb_buckets )

    pals.must_equal @pals
  end

  it "produit le resultat correct de facon parallele avec parallelisme de donnees" do
    pals = trouver_palindromes_par_donnees( @mots, @nb_buckets )

    pals.must_equal @pals
  end

  it "produit le resultat correct de facon parallele avec parallelisme de resultat" do
    pals = trouver_palindromes_par_resultat( @mots, @nb_buckets )

    pals.must_equal @pals
  end
end
