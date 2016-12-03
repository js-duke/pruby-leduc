require_relative 'spec_helper'
require 'pruby'
require 'system'
require 'set'

describe PRuby do

  describe "#bornes_de_tranche" do
    it "repartit egalement si cela divise" do
      [].bornes_de_tranche(0, 4, 1).must_equal [0, 3]

      [].bornes_de_tranche(0, 4, 2).must_equal [0, 1]
      [].bornes_de_tranche(1, 4, 2).must_equal [2, 3]
    end

    it "repartit equitablement si cela ne divise pas" do
      [].bornes_de_tranche(0, 4, 3).must_equal [0,1]
      [].bornes_de_tranche(1, 4, 3).must_equal [2,2]
      [].bornes_de_tranche(2, 4, 3).must_equal [3,3]
    end

    it "repartit equitablement si cela ne divise pas (bis)" do
      [].bornes_de_tranche(0, 5, 3).must_equal [0,1]
      [].bornes_de_tranche(1, 5, 3).must_equal [2,3]
      [].bornes_de_tranche(2, 5, 3).must_equal [4,4]
    end

    it "repartit equitablement si le nombre d'elements est plus petit que le nombre de threads" do
      [].bornes_de_tranche(0, 2, 3).must_equal [0,0]
      [].bornes_de_tranche(1, 2, 3).must_equal [1,1]
      [].bornes_de_tranche(2, 2, 3).must_equal [2,1]
    end

    it "repartit equitablement si le nombre d'elements est plus petit que le nombre de threads" do
      [].bornes_de_tranche(0, 3, 10).must_equal [0,0]
      [].bornes_de_tranche(1, 3, 10).must_equal [1,1]
      [].bornes_de_tranche(2, 3, 10).must_equal [2,2]
      (3...10).each do |k|
        [].bornes_de_tranche(k, 3, 10).must_equal [3,2]
      end
    end

    it "repartit equitablement le plus possible" do
      [].bornes_de_tranche(0, 3002, 3).must_equal [0,1000]
      [].bornes_de_tranche(1, 3002, 3).must_equal [1001,2001]
      [].bornes_de_tranche(2, 3002, 3).must_equal [2002,3001]
    end
  end

  describe Range do
    describe "#pmap" do
      it "retourne un tableau vide si la cible est vide" do
        r = (1..0).pmap { |x| 2 * x }
        r.must_equal []
      end

      it "retourne un simple tableau si la cible n'est pas vide" do
        n = 1093
        r = (1..n).pmap  { |x| 2*x }
        r.must_equal (1..n).map { |x| 2*x }
      end

      it "retourne un simple tableau si la cible n'est pas vide, meme si moins d'element que le nombre de threads" do
        r = (1..3).pmap(nb_threads: 5)  { |x| 2*x }
        r.must_equal [2, 4, 6]
      end
    end

    describe "#peach" do
      it "n'a aucun effet si vide" do
        r = []
        (1..0).peach { |x| r << 10*x }
        r.must_equal []
      end

      it "s'execute pour chacun des elements lorsque pas vide" do
        n = 1002
        nbt = 7
        r = Array.new( nbt ) { [] }
        (1..n).peach(nb_threads: nbt) { |x| r[PRuby.thread_index] << 10*x }
        r.flatten.sort.must_equal (1..n).map{ |x| 10*x }
      end
    end
  end

  describe Array do
    describe "#pmap" do
      it "signale une erreur si 0 thread" do
        -> { [1..10].pmap(nb_threads: 0) {|x| 2*x} }.must_raise DBC::Failure
      end

      it "retourne un tableau vide si vide" do
        r = [].pmap  { |x| 2*x }
        r.must_equal []
      end

      it "retourne un tableau de meme taille avec la fonction appliquee a chaque element" do
        r = [1,2,3,4].pmap  { |x| 2*x }
        r.must_equal [2, 4, 6, 8]
      end

      it "retourne un tableau de meme taille meme avec un gros tableau" do
        r = (1..10000).to_a.pmap  { |x| 2*x }
        r.must_equal (1..10000).to_a.map { |x| 2*x }
      end

      it "utilise le bon nombre de threads si specifie" do
        (1..10).to_a.pmap(nb_threads: 7) {|x| 2*x}
        PRuby.nb_threads_used.must_equal 7
      end

      it "utilise le nombre de cores comme nombre de threads si rien n'est specifie" do
        (1..10).to_a.pmap {|x| 2*x}
        PRuby.nb_threads_used.must_equal [System::CPU.count,10].min
      end

      it "produit le bon resultat avec un petit tableau" do
        a = (1..10).to_a.map {|x| x}
        r = a.pmap(dynamic: 2, nb_threads: 3) { |x| 10 * x }

        PRuby.nb_threads_used.must_equal 3
        r.must_equal a.map{ |x| 10*x }
      end

      it "produit le bon resultat avec un gros tableau" do
        a = (1..1001).to_a.map {|x| x}
        r = a.pmap(dynamic: 6, nb_threads: 7) { |x| 10 * x }

        PRuby.nb_threads_used.must_equal 7
        r.must_equal a.map{ |x| 10*x }
      end
    end

    describe "#peach" do
      it "n'a aucun effet si vide" do
        a = []
        r = []
        a.peach { |x| r << 10*x }
        a.must_equal []
        r.must_equal []
      end

      context "allocation statique implicite (par defaut) des taches" do
        it "traite tous les elements du  tableau" do
          a = [10, 20, 30, 40]
          r = Array.new(3) { [] }
          a.peach(nb_threads: 3) { |x| r[PRuby.thread_index] << 10*x }
          a.must_equal [10, 20, 30, 40]
          r.must_equal [ [100, 200], [300], [400] ]
        end
      end

      context "allocation statique explicite des taches" do
        it "traite tous les elements du  tableau" do
          a = [10, 20, 30, 40]
          r = Array.new(3) { [] }
          a.peach(nb_threads: 3, static: true) { |x| r[PRuby.thread_index] << 10*x }
          a.must_equal [10, 20, 30, 40]
          r.must_equal [ [100, 200], [300], [400] ]
        end
      end
    end

    describe "#peach_index" do

      context "repartition statique" do
        it "produit par defaut une repartition equitable, avec au plus un de differences, meme pour un petit nombre d'elements" do
          a = [10, 20, 30, 40]
          r = Array.new(3) { [] }
          a.peach(nb_threads: 3) { |x| r[PRuby.thread_index] << PRuby.thread_index }
          PRuby.nb_threads_used.must_equal 3
          r[0].size.must_equal 2
          r[1].size.must_equal 1
          r[2].size.must_equal 1
        end

        it "produit par defaut une repartition equitable, avec au plus un de difference" do
          a = (0..3001).to_a
          r = Array.new(3002)
          a.peach_index(nb_threads: 3) { |i| r[i] = PRuby.thread_index }
          PRuby.nb_threads_used.must_equal 3
          r[0].must_equal r[1000]
          r.select { |x| x == r[0] }.size.must_equal 1001
          r.select { |x| x == r[1001] }.size.must_equal 1001
          r.select { |x| x == r[2002] }.size.must_equal 1000
        end
      end

      context "repartition cyclique" do
        it "repartit par paquet de 1" do
          a = [10, 20, 30, 40, 50, 60, 70]
          r = Array.new(7)
          a.peach_index(static: 1, nb_threads: 3) { |k| r[k] = PRuby.thread_index }
          PRuby.nb_threads_used.must_equal 3
          r[0].must_equal r[3]
          r[0].must_equal r[6]
          r[1].must_equal r[4]
          r[2].must_equal r[5]
        end

        it "repartit par paquet de 2" do
          a = [10, 20, 30, 40, 50, 60, 70]
          r = Array.new(7)
          a.peach_index(static: 2, nb_threads: 3) { |k| r[k] = PRuby.thread_index }
          PRuby.nb_threads_used.must_equal 3
          r[0].must_equal r[1]
          r[0].must_equal r[6]
          r[2].must_equal r[3]
          r[4].must_equal r[5]
        end

        it "produit le bon resultat avec un gros tableau" do
          a = (1..1001).to_a.map {|x| x}
          r = a.pmap(static: 3) { |x| 10 * x }
          r.must_equal a.map{ |x| 10*x }
        end
      end

      context "repartition dynamique" do
        it "repartit par paquet de 1" do
          a = [10, 20, 30, 40, 50, 60, 70]
          r = Array.new(7)
          a.peach_index(dynamic: 1, nb_threads: 3) { |k| r[k] = PRuby.thread_index }
          PRuby.nb_threads_used.must_equal 3

          r.to_set.size <= 3
        end

        it "repartit par paquet de 2" do
          a = [10, 20, 30, 40, 50, 60, 70]
          r = Array.new(7)
          a.peach_index(dynamic: 2, nb_threads: 3) { |k| r[k] = PRuby.thread_index }
          PRuby.nb_threads_used.must_equal 3

          r.to_set.size <= 3
          (0...7).step(2).each do |k|
            r[k].must_equal r[k+1] if k+1 < 7
          end
        end
      end

    end
  end
end
