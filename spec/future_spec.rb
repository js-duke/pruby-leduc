require_relative 'spec_helper'
require 'pruby'

describe PRuby do
  describe ".future" do
    describe "les messages d'erreurs" do
      it "signale une erreur si aucun argument n'est fourni" do
        lambda{ PRuby.future }.must_raise DBC::Failure
      end

      it "signale une erreur si plusieurs arguments sont fournis" do
        lambda{ PRuby.future ->{ puts "lambda" } { puts "bloc" } }.must_raise DBC::Failure
      end

      it "signale une erreur si l'argument explicite n'est pas un Proc" do
        lambda{ PRuby.future 10 }.must_raise DBC::Failure
      end
    end

    describe "leur execution se fait en parallele et ne bloque qu'au moment du get" do
      context "il y a un seul future et son corps s'endort" do
        it "ne bloque pas l'appelant mais bloque au moment du get" do
          nbt = PRuby.nb_tasks_created
          x = 3
          f = PRuby.future ->{ sleep 0.5; x += 4; 22 }
          x.must_equal 3

          f.value.must_equal 22
          x.must_equal 7

          (PRuby.nb_tasks_created-nbt).must_equal 1
        end
      end

      context "il y a plusieurs futures et tous dorment dans le corps" do
        it "ne bloquent pas l'appelant mais bloquent l'appelant eau moment du get" do
          nbt = PRuby.nb_tasks_created
          x = 0
          f2 = PRuby.future { sleep 1.0; x *= 10; 99 }
          f1 = PRuby.future { sleep 0.5; x += 3  }
          x.must_equal 0
          x.must_equal 0

          f1.value.must_equal 3
          x.must_equal 3

          f2.value.must_equal 99
          x.must_equal 30

          (PRuby.nb_tasks_created-nbt).must_equal 2
        end
      end
    end
  end
end
