require_relative 'spec_helper'
require 'pruby'
require 'system'
require 'set'

def create_hash(n)
  hash = Hash.new
  (1..n).each do |k| 
    if block_given?
      hash[k] = yield k
    else
      hash[k] = k
    end
  end
  hash
end

describe PRuby do
  describe "#collect_tranche" do
    it "retoune la bonne taille de tranche" do
      hash = { "1" => 1, "2" => 2, "3" => 3, "4" => 4, "1" => 1 }
      expected = [ [["1",1],["2",2]], [["3",3],["4",4]], [["1",1]]]
      index = 0
      r = hash.collect_tranche(2) do |array|
        array.must_equal(expected[index])
        index+=1
        return index
      end
      r.must_equal [1, 2, 3, 4, 5]
    end

    it "pas d'erreur si aucune ou plus petite tranche" do
      hash = { "1" => 1 }
      hash2 = { }
      expected = [["1",1]]
      hash.collect_tranche(2) do |array|
        array.must_equal(expected)
      end
      called_block = false
      hash2.collect_tranche(2) do |array|
        called_block = true
      end
      called_block.must_equal false
    end
  end

  describe "#cyclic_each" do
    it "cyclic works" do
      hash = { "1" => 1, "2" => 2, "3" => 3, "4" => 4, "5" => 5 }
      expected_0 = [["1", 1], ["2",2], ["5", 5]]
      expected_1 = [["3", 3], ["4", 4]]
      
      index = 0
      hash.cyclic_each(2, 2, 0) do |key, value|
        [key, value].must_equal expected_0[index]
        index+=1
      end

      index = 0
      hash.cyclic_each(2, 2, 1) do |key, value|
        [key, value].must_equal expected_1[index]
        index+=1
      end
    end

  end

  describe "pmap" do
    it "retourne un hash vide si la cible est vide" do
      r = Hash.new.pmap { |k,v| 2 * v }
      r.must_equal(Hash.new)
    end

    it "retourne un simple tableau si la cible n'est pas vide" do
      hash = create_hash(10)
      r = hash.pmap  { |k,v| 2*v }
      r.must_equal(create_hash(10) { |k| 2*k }) 
    end

    it "retourne un simple hash si la cible n'est pas vide, meme si moins d'element que le nombre de threads" do
      hash = create_hash(3)
      r = hash.pmap(nb_threads: 6)  { |k,v| 2*v }
      r.must_equal(create_hash(3) { |k| 2*k })
    end

    it "signale une erreur si 0 thread" do
      hash = create_hash(100)
      -> { hash.pmap(nb_threads: 0) {|k,v| 2*v} }.must_raise DBC::Failure
    end

    it "retourne un hash de meme taille meme avec un gros tableau" do
      hash = create_hash(1000)
      r = hash.pmap  { |k,v| 2*v }
      r.must_equal(create_hash(1000) { |k| 2*k })
    end

    it "utilise le bon nombre de threads si specifie" do
      a = create_hash(10)
      a.pmap(nb_threads: 7) {|k,v| 2*v}
      PRuby.nb_threads_used.must_equal 7
    end

    it "utilise le nombre de cores comme nombre de threads si rien n'est specifie" do
      a = create_hash(10)
      a.pmap {|k,v| 2*v}
      PRuby.nb_threads_used.must_equal [System::CPU.count,10].min
    end

    it "produit le bon resultat avec un petit tableau" do
      a = create_hash(10)
      r = a.pmap(dynamic: 2, nb_threads: 3) { |k,v| 10*v }

      PRuby.nb_threads_used.must_equal 3
      r.must_equal(create_hash(10) { |k| 10*k })
    end

    it "produit le bon resultat avec un gros tableau" do
      a = create_hash(1000)
      r = a.pmap(dynamic: 6, nb_threads: 7) { |k,v| 2*v }

      PRuby.nb_threads_used.must_equal 7
      r.must_equal(create_hash(1000) { |k| 2*k })
    end
  end

  describe "#peach" do
    it "n'a aucun effet si vide" do
      a = Hash.new
      r = []
      a.peach { |k,v| r << 10*x }
      a.must_equal(Hash.new)
      r.must_equal []
    end

    context "allocation statique implicite (par defaut) et cyclique des taches" do
      it "traite tous les elements du  tableau" do
        a = create_hash(4) { |k| k*10 }
        r = PRuby::ConcurrentHash.new
        a.peach(nb_threads: 3) { |k,v| r[k] = 10*v }
        a.must_equal(create_hash(4) { |k| k*10 })
        r.must_equal(create_hash(4) { |k| k*100 })
      end
    end

    context "allocation statique explicite et cyclique des taches" do
      it "traite tous les elements du  tableau" do
        a = create_hash(6) { |k| k*10 }
        r = PRuby::ConcurrentHash.new
        a.peach(nb_threads: 3, static: 2) { |k,v| r[k] = 10*v }
        a.must_equal(create_hash(6) { |k| k*10 })
        r.must_equal(create_hash(6) { |k| k*100 })
      end
    end
  end
end