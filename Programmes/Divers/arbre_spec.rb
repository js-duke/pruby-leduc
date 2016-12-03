$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'arbre'

describe "somme" do
  let(:f10) { Feuille.new 10 }
  let(:f20) { Feuille.new 20 }
  let(:f30) { Feuille.new 30 }
  let(:f40) { Feuille.new 40 }
  let(:a0)  { Noeud.new(f10, f20) }
  let(:a1)  { Noeud.new(f30, f40) }
  let(:a2)  { Noeud.new( a0, a1 ) }

  let(:a) { Noeud.new( Noeud.new( Feuille.new(10),
                                  Feuille.new(30) ),
                       Feuille.new( 40 ) ) }

  it "fait la somme pour une feuille" do
    f10.somme.must_equal 10
  end

  it "imprime l'arbre a" do
    #puts a.inspect
  end

  it "somme l'arbre a" do
    a.somme.must_equal 80
  end

  it "fait la somme pour une feuille" do
    f10.somme.must_equal 10
  end

  it "fait la somme pour un noeud simple" do
    a0.somme.must_equal 30
  end

  it "fait la somme pour un noeud complexe" do
    a2.somme.must_equal 100
  end
end
