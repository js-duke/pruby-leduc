$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'histogramme'

describe "histogramme" do
  before do
    @nb_buckets = 5
    @mots = ["abc", "abba", "kayak", "foo", "foof", "aA", "aaa", "b", "ddDDd"]

    @histo = Array.new(@nb_buckets){ [] }

    @histo = [2, 1, 1, 3, 2]
  end

  it "produit le resultat correct de facon sequentielle" do
    histo = histogramme_seq( @mots, @nb_buckets )

    histo.must_equal @histo
  end

  it "produit le resultat correct de facon parallele avec parallelisme de donnees avec mutex" do
    histo = histogramme_par_donnees_avec_mutex( @mots, @nb_buckets )

    histo.must_equal @histo
  end

  it "produit le resultat correct de facon parallele avec parallelisme de donnees" do
    histo = histogramme_par_donnees( @mots, @nb_buckets )

    histo.must_equal @histo
  end

  it "produit le resultat correct de facon parallele avec parallelisme de resultat" do
    histo = histogramme_par_resultat( @mots, @nb_buckets )

    histo.must_equal @histo
  end
end
