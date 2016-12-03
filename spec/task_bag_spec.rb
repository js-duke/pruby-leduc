require_relative 'spec_helper'
require 'pruby'
require 'dbc'

describe PRuby::TaskBag do
  describe ".new" do
    it "cree un sac initialement actif" do
      tb = PRuby::TaskBag.new( 2 )
      refute tb.done?
    end
  end

  describe "#put et #get" do
    it "ajoute et retire l'item par le meme thread" do
      tb = PRuby::TaskBag.new( 1 )
      tb.put( 10 )
      tb.put( 20 )
      tb.get.must_equal 10
      tb.get.must_equal 20
    end

    it "ajoute et retire l'item de threads differents" do
      tb = PRuby::TaskBag.new( 2 )
      t1 = PRuby.future { sleep 0.05; tb.get }
      t2 = PRuby.future { sleep 0.15; tb.get }
      PRuby.future { tb.put( 10 ); tb.put( 20 ) }
      t1.value.must_equal 10
      t2.value.must_equal 20
    end

    it "ajoute et retire l'item de threads differents (bis)" do
      tb = PRuby::TaskBag.new( 3 )
      PRuby.future { tb.put(10) }
      PRuby.future { tb.put(20) }
      PRuby.future { tb.get + tb.get }.value.must_equal 30
    end
  end

  describe "#get" do
    it "devient inactif des que les threads bloquent" do
      tb = PRuby::TaskBag.new( 2 )
      PRuby.future { tb.get }
      PRuby.future { tb.get }
      jiggle
      assert tb.done?
    end
  end

  describe "#wait_done" do
    it "bloque le coordonnateur en attente des deux travailleurs" do
      tb = PRuby::TaskBag.new( 2 )
      x = 0
      PRuby.future { x += 1 if tb.get }
      PRuby.future { jiggle; x += 2 if tb.get }
      tb.wait_done
      assert tb.done?
      x.must_equal 0
    end

    it "bloque le coordonnateur jusqu'a ce que les travailleurs deviennent inactifs" do
      n = 237
      nb_workers = 7

      tb = PRuby::TaskBag.new( nb_workers )
      (1..n).each { |i| tb.put i }

      refute tb.done?
      res = Array.new nb_workers
      nb_workers.times do |i|
        PRuby.future do
          jiggle
          r = 0
          while task = tb.get
            r += task
          end
          res[i] = r
        end
      end

      tb.wait_done
      assert tb.done?

      r = 0
      nb_workers.times do |i|
        r += res[i]
      end

      r.must_equal n * (n+1) / 2
    end
  end

  describe "#each" do
    it "distribue les taches entre les differents threads" do
      n = 237
      nb_workers = 7

      tb = PRuby::TaskBag.new( nb_workers )
      (1..n).each { |i| tb.put i }

      res = (0...nb_workers).map do |i|
        PRuby.future do
          r = 0
          tb.each do |task|
            jiggle / 10
            r += task
          end
          [i, r]
        end
      end
      .map(&:value)

      threads_actifs = res.map(&:first)
      (0...nb_workers).all? { |k| threads_actifs.include? k }

      tot = res.reduce(0) { |tot, x| tot + x.last }
      tot.must_equal n * (n+1) / 2
    end

    it "signale une erreur si on utilise get" do
      tb = PRuby::TaskBag.new( 2 )
      tb.put 10
      proc { tb.each { |k| puts tb.get } }.must_raise RuntimeError
    end
  end

  describe "#create_and_run" do
    it "distribue les taches entre les differents threads" do
      n = 2378
      nb_workers = 7

      mutex = Mutex.new
      workers = []
      resultats = PRuby::TaskBag.create_and_run( nb_workers, *1..n ) do |tb, k|
        mutex.synchronize { workers << k }
        somme = 0
        tb.each do |task|
          somme += task
        end

        somme
      end

      total = resultats.reduce(0) { |tot, x| tot + x }
      total.must_equal n * (n+1) / 2
      workers.sort.must_equal [*0...nb_workers]
    end

    it "signale une erreur si on utilise get" do
      proc do
        tb = PRuby::TaskBag.run( 2, 10 ) do |tb|
          tb.each { |k| puts tb.get }
        end
      end.must_raise RuntimeError
    end
  end
end
