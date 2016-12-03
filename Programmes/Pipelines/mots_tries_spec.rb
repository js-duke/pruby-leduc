$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'mots_tries'

describe "trier_mots_uniques" do
  before do
    @donnees  = ["abc ** abc abc dsds cssa", "ssdsx", "fssfd  dfdf", "ss **xtx*zy"]
    @attendus = ["abc", "cssa", "dfdf", "dsds", "fssfd", "ss", "ssdsx"]
  end

  it "produit un resultat" do
    r = Array.new
    trier_mots_uniques( @donnees, r )
    r.must_equal @attendus
  end
end
