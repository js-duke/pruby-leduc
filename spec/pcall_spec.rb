require_relative 'spec_helper'
require 'pruby'
require 'system'

describe PRuby do

  describe ".pcall" do

    it "bloque jusqu'a ce que les appels aient termine et l'execution se fait de facon entrelacee" do
      x = 1
      PRuby.pcall\
      ->{ sleep 1.0; x += 2 },
      ->{ sleep 0.5; x *= 10 },
      ->{ x += 100 }
      x.must_equal (1 + 100)*10+2
    end

    it "bloque jusqu'a ce que les appels aient termine et l'execution se fait de facon entrelacee (bis)" do
      x = 1
      PRuby.pcall\
      ->{ sleep 0.5; x += 2 },
      ->{ sleep 1.0; x *= 10 },
      ->{ x += 100 }
      x.must_equal ((1 + 100)+2)*10
    end

    describe "effets des variables locales deja declaree ou non" do
      context "une variable deja definie existe dans l'appelant" do
        it "la modifie" do
          r1 = 0
          f = -> { r1 = 10 }
          f.call
          (r1 == 10).must_equal true
        end
      end

      context "des variables deja definies existent dans l'appelant" do
        it "les modifie dans de multiples lamdbas independanta" do
          r1 = 1
          r2 = 2
          r3 = 3
          PRuby.pcall \
          -> { r1 += 1 },
          -> { jiggle; r2 += 2 },
          -> { r3 += 3 }

          r1.must_equal 2
          r2.must_equal 4
          r3.must_equal 6
        end
      end

      context "il n'y a pas de variable deja definie dans l'appelant" do
        it "affecte une nouvelle variable locale dans l'appele, et donc signale une erreur pour variable inexistante avant et apres l'appel" do
          -> { r1 == 10 }.must_raise NameError
          f = -> { r1 = 10 }
          f.call
          -> { r1 == 10 }.must_raise NameError
        end
      end


    end

    describe "argument indiquant la sorte de thread" do
      it "signale une erreur si le nombre d'arguments n'est pas suffisant" do
        -> { PRuby.pcall :FOO }.must_raise DBC::Failure
      end

      it "signale une erreur si le nombre d'arguments n'est pas suffisant" do
        -> { PRuby.pcall :REGULAR_THREAD, ->{} }.must_raise DBC::Failure
      end

      it "signale une erreur si le symbole n'est pas valide" do
        -> { PRuby.pcall :FOO, ->{} }.must_raise DBC::Failure
      end

      it "utilise les threads reguliers lorsque demande, avec un thread par element appele" do
        PRuby.nb_threads_used = 8
        PRuby.pcall :THREAD, ->{}, ->{}, ->{}
        PRuby.nb_threads_used.must_equal 3
      end

      it "utilise les fork join threads lorsque demande, avec le nombre de threads qui depend du nombre de coeurs" do
        PRuby.pcall :FORK_JOIN_TASK, ->{}, ->{}, ->{}
        PRuby.nb_threads_used.must_equal System::CPU.count
      end
    end
  end

  describe ".pcall un ou plusieurs ranges pour des instances multiples" do
    it "genere une erreur si le lambda qui doit etre active n'a pas un argument pour recevoir l'index" do
      -> { PRuby.pcall (0...10), -> {} }.must_raise DBC::Failure
    end

    it "genere une erreur si un Range apparait trop tard, i.e., apres des lambdas sans range" do
      -> { PRuby.pcall (0...10), -> {}, ->{}, (0...10), ->{} }.must_raise DBC::Failure
    end

    context "il y a un seul range et lambda" do
      it "genere les instances paralleles" do
        n = 100
        r = Array.new(n)
        PRuby.pcall 0...n, lambda { |i| r[i] = i }
        r.must_equal (0...n).map { |i| i }
      end
    end

    context "il y a plusieurs ranges et lambdas" do
      it "executent tous" do
        n1 = 3
        n2 = 100
        r = Array.new(n1)
        s = Array.new(n2)
        t = nil

        PRuby.pcall\
        (0...n1), lambda { |i| r[i] = i },
        100...(100+n2), lambda { |i| jiggle; s[i-100] = 10*(i-100) },
        lambda { t = 22 }

        r.must_equal (0...n1).map { |i| i }
        s.must_equal (100...(100+n2)).map { |i| 10*(i-100) }
        t.must_equal 22
      end
    end
  end

end
