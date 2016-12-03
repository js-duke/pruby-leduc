require_relative 'spec_helper'
require 'pruby'

class Arbre
  attr_reader :valeur

  def initialize( valeur )
    @valeur = valeur
  end
end

class Feuille < Arbre
  def somme
    @valeur
  end
end

class Noeud < Arbre
  def initialize( valeur, *enfants )
    @enfants = enfants
    super( valeur )
  end

  def somme
    @valeur + @enfants.preduce(0, final_reduce: :+) do |total, enf|
      total + enf.somme
    end
  end
end

describe PRuby do
  describe Array do
    describe "#preduce" do
      let(:a1) { Noeud.new( 1,
                            Feuille.new(2),
                            Feuille.new(3) ) }

      it "produit bon resultat pour a1" do
        a1.somme.must_equal 6
      end
    end

  end
end
