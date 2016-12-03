$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'mots_tries'

describe "trier_mots_uniques" do
  before do
    @donnees  = ["abc ** abc abc dsds cssa", "ssdsx", "fssfd  dfdf", "ss **xtx*zy"]
    @attendus = ["abc", "cssa", "dfdf", "dsds", "fssfd", "ss", "ssdsx"]
  end

  [:trier_mots_uniques, :trier_mots_uniques_apply, :trier_mots_uniques_apply_bis].each do |methode|
    it "produit le resultat avec la methode #{methode}" do
      r = Array.new
      send methode, @donnees, r
      r.must_equal @attendus
    end
  end
end
