$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'polynome'

describe Polynome do
  describe "to_s" do
    it "retourne 0 pour" do
      Polynome.new(0, 0).to_s.must_equal "0"
    end

    it "retourne un simple entier pour un polynome de taille 1" do
      Polynome.new(2).to_s.must_equal "2"
    end

    it "retourne un x sans exposant pour un polynome de taille 2" do
      Polynome.new(1, 2).to_s.must_equal "2*x+1"
    end

    it "retourne les exposants appropries pour un polynome de taille 3" do
      Polynome.new(1, 2, 4).to_s.must_equal "4*x^2+2*x+1"
    end

    it "ignore les 0 au milieu" do
      Polynome.new(1, 0, 4, 0, 5).to_s.must_equal "5*x^4+4*x^2+1"
    end

    it "ignore les 0 au milieu et a la fin" do
      Polynome.new(0, 0, 4, 0, 5).to_s.must_equal "5*x^4+4*x^2"
    end
  end

  describe "#[]" do
    it "accede aux coefficients d'un simple entier" do
      p = Polynome.new( 10 )
      p[0].must_equal 10
      lambda { p[-1] }.must_raise DBC::Failure
      lambda { p[1] }.must_raise DBC::Failure
    end

    it "accede aux coefficients d'un polynome avec plusieurs elements" do
      p = Polynome.new( 10, 20, 0, 30 )
      p[0].must_equal 10
      p[1].must_equal 20
      p[2].must_equal 0
      p[3].must_equal 30
      lambda { p[4] }.must_raise DBC::Failure
    end
  end

  describe ".new" do
    it "supprime les zeros non significatifs" do
      p = Polynome.new( 10, 0, 30, 0, 0 )
      p[0].must_equal 10
      p[1].must_equal 0
      p[2].must_equal 30
      lambda { p[3] }.must_raise DBC::Failure
    end

    it "supprime les zeros non significatifs sauf pour un seul" do
      p = Polynome.new( 0, 0, 0, 0, 0 )
      p[0].must_equal 0
      lambda { p[1] }.must_raise DBC::Failure
    end
  end

  describe "#==" do
    it "indique qu'un polynome est egal a lui-meme" do
      p = Polynome.new( 10, 30, 0, 40 )
      (p == p).must_equal true
    end

    it "ignore les zeros non significatifs" do
      p1 = Polynome.new( 10, 30, 0, 40 )
      p2 = Polynome.new( 10, 30, 0, 40, 0, 0, 0 )
      (p1 == p2).must_equal true
      (p2 == p1).must_equal true
    end

    it "retourne faux des qu'un element est different" do
      p1 = Polynome.new( 10, 30, 0, 40 )
      p2 = Polynome.new( 10, 0, 0, 40, 0, 0, 0 )
      (p1 == p2).must_equal false
      (p2 == p1).must_equal false
    end

    it "retourne faux si la partie differente est apres la fin" do
      p1 = Polynome.new( 10, 30, 0, 40 )
      p2 = Polynome.new( 10, 30, 0, 40, 2 )
      (p1 == p2).must_equal false
      (p2 == p1).must_equal false
    end
  end

  describe "#+" do
    it "additionne deux polynomes de meme taille" do
      p1 = Polynome.new( 10, 30, 0, 40 )
      p2 = Polynome.new( 10, 30, 0, 40 )
      (p1 + p2).must_equal Polynome.new( 20, 60, 0, 80 )
      (p2 + p1).must_equal Polynome.new( 20, 60, 0, 80 )
    end

    it "additionne deux polynomes de tailles tres differentes" do
      p1 = Polynome.new( 10, 30 )
      p2 = Polynome.new( 10, 30, 0, 40, 80 )
      (p1 + p2).must_equal Polynome.new( 20, 60, 0, 40, 80 )
      (p2 + p1).must_equal Polynome.new( 20, 60, 0, 40, 80 )
    end

    it "additionne deux polynomes avec des zeros non significatifs" do
      p1 = Polynome.new( 10, 30, 0, 40, 0, 0 )
      p2 = Polynome.new( 10, 30, 0, 40, 0, 0, 0 )
      (p1 + p2).must_equal Polynome.new( 20, 60, 0, 80, 0, 0, 0 )
      (p2 + p1).must_equal Polynome.new( 20, 60, 0, 80, 0, 0, 0 )
    end

    it "supprime les zeros non significatifs" do
      p1 = Polynome.new( 10, 30, 0, 40, 10, 20 )
      p2 = Polynome.new( 10, 30, 0, 40, -10, -20 )
      (p1 + p2).must_equal Polynome.new( 20, 60, 0, 80 )
      (p2 + p1).must_equal Polynome.new( 20, 60, 0, 80 )
    end
  end


  describe "#*" do
    Polynome::SORTES_DE_MULTIPLICATION.keys.each do |sorte|
      describe "#{sorte}" do
        before do
          Polynome.sorte_de_multiplication = sorte
        end

        it "multiplie deux entiers" do
          p1 = Polynome.new( 10 )
          p2 = Polynome.new( 20 )
          (p1 * p2).must_equal Polynome.new( 200 )
          (p2 * p1).must_equal Polynome.new( 200 )
        end

        it "mulitplie deux polynomes de tailles differentes" do
          p1 = Polynome.new( 1, 2 )
          p2 = Polynome.new( 10, 20, 30, 40 )
          r = Polynome.new( 10, 40, 70, 100, 80 )
          (p1 * p2).must_equal r
          (p2 * p1).must_equal r
        end

        it "multiplie deux gros polynomes simples" do
          n = 100
          p1 = Polynome.new( *((1..n).map{ 1 }) )
          p2 = Polynome.new( *((1..n).map{ 1 }) )
          moitie = (1..n).map{ |i| i }
          r = Polynome.new( *(moitie + moitie.reverse[1..-1]) )
          (p1 * p2).must_equal r
          (p2 * p1).must_equal r
        end
      end
    end
  end
end
