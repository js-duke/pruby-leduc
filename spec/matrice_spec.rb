require_relative 'spec_helper'
require 'matrice'

describe Matrice do
  describe ".new" do
    it "cree par defaut une matrice carre" do
      a = Matrice.new(2)
      a.to_a.must_equal [[nil, nil], [nil, nil]]
    end

    it "cree une matrice avec la meme valeur partout" do
      a = Matrice.new(2, 3) { 0 }
      a.to_a.must_equal [[0, 0, 0], [0, 0, 0]]
    end

    it "cree une matrice avec differentes valeurs" do
      a = Matrice.new(2, 3) { |i,j| i + j }
      a.to_a.must_equal [[0, 1, 2], [1, 2, 3]]
    end
  end

  describe "#nb_lignes et #nb_colonnes" do
    it "retourne le meme nombre de lignes et de colonnes" do
      a = Matrice.new(2, 5)
      a.nb_lignes.must_equal 2
      a.nb_colonnes.must_equal 5
    end

    it "retourne le meme nombre de lignes et de colonnes quand colonnes pas indique" do
      a = Matrice.new(2)
      a.nb_lignes.must_equal 2
      a.nb_colonnes.must_equal 2
    end
  end

  describe "#[]" do
    it "retourne l'element approprie" do
      a = Matrice.new(3, 4) { |i,j| i + j }
      a[2, 2].must_equal 4
    end

    it "genere une erreur si hors borne" do
      a = Matrice.new(3, 4) { |i,j| i + j }
      lambda { a[0, -1] }.must_raise DBC::Failure
      lambda { a[-1, 2] }.must_raise DBC::Failure
      lambda { a[3, 2] }.must_raise DBC::Failure
      lambda { a[0, 4] }.must_raise DBC::Failure
    end
  end

  describe "#[]=" do
    it "modifie l'element approprie" do
      a = Matrice.new(3, 4) { |i,j| i + j }
      a[2, 2].must_equal 4
      a[2, 2] = 23
      a[2, 2].must_equal 23
    end

    it "modifie les elements appropries" do
      a = Matrice.new(3, 4)
      a.nb_lignes.times do |i|
        a.nb_colonnes.times do |j|
          a[i,j].must_equal nil
        end
      end

      a.nb_lignes.times do |i|
        a.nb_colonnes.times do |j|
          a[i,j] = i * j
        end
      end

      a.nb_lignes.times do |i|
        a.nb_colonnes.times do |j|
          a[i,j].must_equal i * j
        end
      end
    end

    it "genere une erreur si hors borne" do
      a = Matrice.new(3, 4) { |i,j| i + j }
      lambda { a[0, -1] = 0 }.must_raise DBC::Failure
      lambda { a[-1, 2] = 0 }.must_raise DBC::Failure
      lambda { a[3, 2] = 0 }.must_raise DBC::Failure
      lambda { a[0, 4] = 2 }.must_raise DBC::Failure
    end
  end

  describe "#ligne et #colonne" do
    before do
      @a = Matrice.new( 4, 2 ) { |i,j| [i, j] }
    end

    it "retourne la 0eme ligne" do
      @a.ligne(0).must_equal [[0,0], [0,1]]
    end

    it "retourne la 0eme colonne" do
      @a.colonne(0).must_equal [[0,0], [1,0], [2,0], [3,0]]
    end

    it "retourne la derniere ligne" do
      @a.ligne(@a.nb_lignes-1).must_equal [[3,0], [3,1]]
    end

    it "retourne la derniere colonne" do
      @a.colonne(@a.nb_colonnes-1).must_equal [[0,1], [1,1], [2,1], [3,1]]
    end

    it "signale une erreur si hors borne" do
      lambda { @a.ligne(@a.nb_lignes) }.must_raise DBC::Failure
      lambda { @a.ligne(-1) }.must_raise DBC::Failure
    end
  end

  describe "#[] avec range" do
    before do
      @a = Matrice.new( 4, 3 ) { |i,j| 10*i+j }
    end

    it "retourne la 0eme et 1eme ligne" do
      @a[0..1, :*].must_equal [[0, 1, 2], [10, 11, 12]]
    end

    it "retourne la 0eme et 1eme ligne" do
      @a[:*, 1..2].must_equal [[1, 2], [11, 12], [21, 22], [31, 32]]
    end

    it "retourne un bloc interne" do
      @a[2..3, 1..2].must_equal [[21, 22], [31, 32]]
    end

    it "retourne une ligne" do
      @a[2, :*].must_equal [20, 21, 22]
    end

    it "retourne toute la matrice" do
      @a[:*, :*].must_equal @a.to_a
    end
  end

  describe "Array#to_matrice" do
    it "tranforme un simple tableau en une matrice ligne" do
      a = [10, 20, 30]
      m = a.to_matrice
      m.must_equal Matrice.new(1, 3, [a])
    end

    it "transforme un tableau de tablean en une matrice identique" do
      a = [[10, 20], [11, 21], [12, 22]]
      m = a.to_matrice
      m.must_equal Matrice.new(3, 2, a)
    end

    it "genere une erreur si pas bien forme" do
      a = [[10, 20], [11, 21], [12]]
      lambda{ m = a.to_matrice }.must_raise DBC::Failure
    end

    it "genere une erreur si applique sur un non-array" do
      a = 10
      lambda{ m = a.to_matrice }.must_raise NoMethodError
    end
  end

  describe "#*" do
    it "genere le bon produit pour des matrices carres" do
      a = Matrice.new(3) { 1 }
      b = Matrice.new(3, 3, [ [2, 2, 2], [2, 2, 2], [2, 2, 2]] )
      c = a * b
      c.must_equal Matrice.new(3) { 6 }
    end

    it "genere le bon produit pour des matrices non carres" do
      a = Matrice.new(3, 4) { |i, j| i }
      b = Matrice.new(4, 2) { |i, j| j }
      c = a * b
      c.must_equal Matrice.new( 3, 2, [[0,0], [0,4], [0,8]] )
    end
  end

  describe "#peach_index_ligne" do
    it "itere sur les differentes lignes d'une petite matrice" do
      nb = 10
      a = Matrice.new(nb, nb) { |i, j| i }
      a.peach_index_ligne do |i|
        a.ligne(i).each_index do |j|
          a[i,j] = 10*i
        end
      end
      a.must_equal Matrice.new(nb, nb) { |i,j| 10*i }
    end

    it "itere sur les differentes lignes d'une grosse matrice" do
      nb = 100
      a = Matrice.new(nb, nb) { |i, j| i }
      a.peach_index_ligne(nb_threads: 7, static: 3) do |i|
        a.ligne(i).each_index do |j|
          a[i,j] = 10*i+j
        end
      end
      a.must_equal Matrice.new(nb, nb) { |i,j| 10*i+j }
    end
  end

  describe "mise en oeuvre lineaire" do
    it "produit une petite matrice egale a l'autre format" do
      a = Matrice.new(3, 4, nil, true) { |i,j| i + j }
      b = Matrice.new(3, 4) { |i,j| i + j }

      a.must_equal b
    end
    it "produit une petite matrice egale a l'autre format" do
      a = Matrice.new(300, 40, nil, true) { |i,j| i + j }
      b = Matrice.new(300, 40) { |i,j| i + j }

      a.must_equal b
    end
  end
end
