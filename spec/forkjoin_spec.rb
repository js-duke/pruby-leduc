######################################################################
# Quelques petits exemples pour bien comprendre et illustrer le
# fonctionnement des operations de la bibliotheque forkjoin
# vs. threads.
######################################################################

require_relative 'spec_helper'
require 'forkjoin'

describe Thread do
  describe ".new" do
    it "cree une activite vraiment parallele et son effet n'est final et visible qu'apres le join" do
      x = 0
      t1 = Thread.new { sleep 0.5; x = 1 }
      t2 = Thread.new { sleep 1.0; x = 2 }
      x.must_equal 0

      t1.value.must_equal 1
      t2.value.must_equal 2
      x.must_equal 2  # Parce que c'est celui qui s'execute le plus tard!
    end
  end
end


describe ForkJoin::Pool do
  before do
    @pool = ForkJoin::Pool.new
  end

  describe "#invoke_all" do
    it "lance l'execution de plusieurs taches" do
      mutex = Mutex.new

      x = 0
      fs = @pool.invoke_all [ ->{ mutex.synchronize { x += 1 } },
                              ->{ mutex.synchronize { x += 2 } }]
      x.must_equal 3
    end

    it "bloque jusqu'a ce que toutes les taches aient termine" do
      x = 0
      fs = @pool.invoke_all [ ->{ sleep 0.5; x = 1 },
                              ->{ sleep 1.0; x = 2 } ]
      x.must_equal 2
    end
  end

  class FJTask < ForkJoin::Task
    def initialize( &body )
      @body = body
    end

    def call
      @r = @body.call
    end
  end

  describe "#submit" do
    it "ne bloque pas, le resultat est un FJTask et le join retourne la valeur" do
      x = 0
      t1 = @pool.submit( FJTask.new { sleep 0.5; x = 1 } )
      t2 = @pool.submit( FJTask.new { sleep 1.0; x = 2 } )

      x.must_equal 0

      t1.class.must_equal FJTask
      t2.join.must_equal 2
      t1.join.must_equal 1
      x.must_equal 2
    end
  end

  describe "#invoke" do
    it "bloque jusqu'a ce que la tache soit terminee et ca retourne un resultat" do
      x = 0

      t1 = @pool.invoke( FJTask.new { sleep 0.5; x = 1 } )
      x.must_equal 1
      t1.must_equal 1

      t2 = @pool.invoke( FJTask.new { sleep 1.0; x = 2 } )
      x.must_equal 2
      t2.must_equal 2
    end
  end
end



=begin

Summary of task execution methods:

                                 Call from non-fork/join clients    Call from within fork/join computations
Arrange async execution          execute(ForkJoinTask)              ForkJoinTask.fork()
Await and obtain result          invoke(ForkJoinTask)               ForkJoinTask.invoke()
Arrange exec and obtain Future   submit(ForkJoinTask)               ForkJoinTask.fork() (ForkJoinTasks are Futures)

Source:

 https://docs.oracle.com/javase/8/docs/api/java/util/concurrent/ForkJoinPool.html

=end
