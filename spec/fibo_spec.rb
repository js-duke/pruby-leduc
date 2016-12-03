require_relative 'spec_helper'
require 'pruby'
require 'system'

describe "Fibonacci avec parallelisme recursif" do
  context "avec .pcall" do
    context "variables non-locales declarees correctement" do
      def fibo( n )
        return n if n == 0 || n == 1

        r1 = r2 = nil
        PRuby.pcall\
        -> { r1 = fibo(n-1) },
        -> { r2 = fibo(n-2) }

        r1 + r2
      end

      context "version avec :THREAD" do
        before do
          PRuby.thread_kind = :THREAD
        end

        it "retourne les cas de base" do
          fibo(0).must_equal 0
          fibo(1).must_equal 1
        end

        it "retourne le bon resultat avec plusieurs appels recursifs" do
          fibo(10).must_equal 55
        end
      end

      context "version avec :FORK_JOIN_TASK" do
        before do
          PRuby.thread_kind = :FORK_JOIN_TASK
        end

        it "retourne les cas de base" do
          fibo(0).must_equal 0
          fibo(1).must_equal 1
        end

        it "retourne le bon resultat avec plusieurs appels recursifs" do
          fibo(10).must_equal 55
        end
      end
    end
  end

  context "variables non-locales ne sont pas declarees corretement" do
    def fibo( n )
      return n if n == 0 || n == 1

      PRuby.pcall\
      -> { r1 = fibo(n-1) },
      -> { r2 = fibo(n-2) }

      r1 ||= 0
      r2 ||= 0
      r1 + r2
    end

    it "ne fonctionne pas avec des appels recursifs" do
      fibo(10).wont_equal 55
    end
  end


  context "avec .future" do
    context "avec un lambda" do
      def fibo( n )
        return n if n == 0 || n == 1

        f2 = PRuby.future -> { fibo(n-2) }
        r1 = fibo(n-1)

        r1 + f2.value
      end

      it "execute avec cas de base" do
        fibo(1).must_equal 1
      end

      it "execute avec plusieurs appels recursifs" do
        fibo(10).must_equal 55
      end
    end

    context "avec un bloc et dans l'autre ordre" do
      def fibo( n )
        return n if n == 0 || n == 1

        f1 = PRuby.future  { fibo(n-1) }
        r2 = fibo(n-2)

        f1.value + r2
      end

      it "execute avec plusieurs appels recursifs" do
        fibo(10).must_equal 55
      end
    end

    context "avec deux futures/lambdas" do
      def fibo( n )
        return n if n == 0 || n == 1

        f1 = PRuby.future -> { fibo(n-1) }
        f2 = PRuby.future -> { fibo(n-2) }

        f1.value + f2.value
      end

      it "execute avec plusieurs appels recursifs" do
        fibo(10).must_equal 55
      end
    end

    describe "nombre de taches creees" do
      def fibo( n )
        return n if n == 0 || n == 1

        f2 = PRuby.future { fibo(n-2) }
        r1 = fibo(n-1)

        r1 + f2.value
      end

      it "execute cas de base sans creer de futures" do
        nbt = PRuby.nb_tasks_created
        fibo(0).must_equal 0
        fibo(1).must_equal 1
        (PRuby.nb_tasks_created-nbt).must_equal 0
      end

      it "execute avec plusieurs appels recursifs et indique le bon nombre de taches" do
        PRuby.with_exact_nb_tasks = true
        nbt = PRuby.nb_tasks_created

        fibo(5).must_equal 5
        (PRuby.nb_tasks_created-nbt).must_equal 7

        fibo(6).must_equal 8
        (PRuby.nb_tasks_created-nbt).must_equal 19
        PRuby.with_exact_nb_tasks = false
      end
    end
  end
end
