require_relative 'spec_helper'
require 'pruby'

describe "pcall" do

  describe "effets des variables locales deja declaree ou non" do
    it "utilise une variable deja definie et c'est ok" do
      r1 = 0
      -> { r1 = 10 }.call
      (r1 == 10).must_equal true
    end

    it "cree une nouvelle variable et donc pas de variable modifiee" do
      -> { r1 = 10 }.call
      -> { r1 == 10 }.must_raise NameError
    end
  end

  describe "effets du for avec variable globale" do
    it "modifie la variable d'iteration" do
      i = 3
      r = 0
      for i in 1..10 do
        r = i
      end

      r.must_equal 10
      i.must_equal 10
    end
  end

  describe "effet du each avec variable globale" do
    it "ne modifie pas la variable d'iteration" do
      i = 3
      r = 0
      (1..10).each do |i|
        r = i
      end

      r.must_equal 10
      i.must_equal 3
    end
  end


end
