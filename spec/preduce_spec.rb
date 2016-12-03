require_relative 'spec_helper'
require 'pruby'
require 'system'
require 'set'

describe PRuby do

  describe Range do
    describe "#preduce" do
      context "l'operation binaire est l'addition = :+" do
        it "retourne l'element neutre si vide" do
          r = (1..0).preduce(21, &:+)
          r.must_equal 21
        end

        it "retourne la somme des elements, avec moins d'elements que de threads" do
          r = (1..4).preduce(0, nb_threads: 5, &:+)
          r.must_equal 10
        end

        it "retourne la somme des elements avec autant de threads que d'elements" do
          r = (1..4).preduce(0, nb_threads: 4, &:+)
          r.must_equal 10
        end

        it "retourne la somme des elements avec plus d'elements que de threads" do
          n = 1022
          r = (1..n).preduce(0, nb_threads: 7, &:+)
          r.must_equal n * (n+1) / 2
        end

        it "retourne la somme meme si moins d'elements que de threads, en ignorant les threads non utilises" do
          r = (1..4).preduce(10, nb_threads: 10, &:+)
          r.must_equal 50
        end

        it "retourne la valeur maximum peu importe la valeur initiale specifiee" do
          r = (1..100).preduce(11, nb_threads: 4) { |x, y| [x, y].max }
          r.must_equal 100

          r = (1..100).preduce(99, nb_threads: 4) { |x, y| [x, y].max }
          r.must_equal 100
        end
      end
    end
  end

  describe Array do
    describe "#preduce" do
      context "l'operation binaire est l'addition :+" do
        it "retourne l'element neutre si vide" do
          r = [].preduce(14) { |x, y| x + y }
          r.must_equal 14
        end

        it "retourne la somme avec plusieurs elements" do
          n = 11*9+3
          a = (1..n).to_a
          r = a.preduce(0, nb_threads: 11) { |x, y| x + y }
          r.must_equal n * (n+1) / 2
        end

        it "retourne la somme, meme avec un element neutre bizarre" do
          a = [10, 11, 12, 13]
          r = a.preduce(2) { |x, y| x + y }
          r.must_equal ([PRuby.nb_threads,4].min * 2 + 10 + 11 + 12 + 13)
        end
      end

      context "l'operation binaire est le maximum" do
        it "retourne la bonne valeur maximum lorsque la valeur initiale est inferieure au maximum" do
          r = (1..100).to_a.shuffle.preduce(29, nb_threads: 4) { |x, y| [x, y].max }
          r.must_equal 100
        end

        it "retourne la valeur initiale si elle est plus grande que le maximum" do
          r = (1..100).to_a.shuffle.preduce(129, nb_threads: 4) { |x, y| [x, y].max }
          r.must_equal 129
        end
      end

      context "l'operation binaire est la concatenation de listes" do
        it "retourne la somme avec plusieurs elements" do
          n = 11*9+3
          a = (1..n).map { |i| Array.new(i, i) }
          r = a.preduce([], nb_threads: 12) { |x, y| x + y }
          r.must_equal a.reduce([]) { |x, y| x + y }
        end
      end

      context "l'operation binaire finale pour combiner les resultats doit etre differente" do
        it "calcule la reduction finale avec un operateur totalement different de l'autre operateur" do
          a = [11, 2, 30, 40, 40, 39, 38, 5, 6]
          r = a.preduce(0, nb_threads: 3, final_reduce: :+) do |m, x|
            [m, x].max
          end

          r_attendu = 30 + 40 + 38

          r.must_equal r_attendu
        end

        it "calcule le nombre d'inversions avec un operateur binaire simple pour la reduction finale" do
          a = [11, 2, 30, 40, 40, 39, 38, 5, 6]

          r = (1...a.size).preduce(0, nb_threads: 3, final_reduce: :+) do |nb, k|
            a[k-1] > a[k] ? (nb + 1) : nb
          end

          r_attendu = (1...a.size).reduce(0) do |nb, k|
            a[k-1] > a[k] ? (nb + 1) : nb
          end

          r.must_equal r_attendu
        end

        it "calcule le nombre d'inversions avec un lambda pour la reduction finale" do
          a = [11, 2, 30, 40, 40, 39, 38, 5, 6]

          plus = lambda { |x, y| x + y }

          r = (1...a.size).preduce(0, nb_threads: 3, final_reduce: plus) do |nb, k|
            a[k-1] > a[k] ? (nb + 1) : nb
          end

          r_attendu = (1...a.size).reduce(0) do |nb, k|
            a[k-1] > a[k] ? (nb + 1) : nb
          end

          r.must_equal r_attendu
        end
      end
    end
  end
end
