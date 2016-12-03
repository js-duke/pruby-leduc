$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'somme_tableaux'

describe "somme de deux tableaux" do
  [:somme_tableaux_seq,
   :somme_tableaux_pcall_fin0,
   :somme_tableaux_pcall_fin1,
   :somme_tableaux_pcall_statique,
   :somme_tableaux_pcall_cyclique,
   :somme_tableaux_peach_fin,
   :somme_tableaux_peach_statique,
   :somme_tableaux_pmap,
  ].each do |somme|

    def effectuer_appel( somme, a, b, nb_threads = PRuby.nb_threads )
      if [:somme_tableaux_seq, :somme_tableaux_pcall_fin0].include? somme
        send somme, a, b
      else
        send somme, a, b, nb_threads
      end
    end

    describe "#{somme}" do
      it "additionne deux vecteurs avec peu d'elements" do
        nb = PRuby.nb_threads
        a = (0...nb).to_a
        b = (0...nb).to_a
        c = effectuer_appel somme, a, b
        c.must_equal somme_tableaux_seq(a, b)
      end

      it "additionne deux vecteurs avec beaucoup d'elements et peu de threads" do
        nb = 100*PRuby.nb_threads
        a = (0...nb).to_a
        b = (0...nb).to_a
        c = effectuer_appel somme, a, b
        c.must_equal somme_tableaux_seq(a, b)
      end

      it "additionne deux vecteurs avec beaucoup d'elements et beaucoup de threads" do
        PRuby.nb_threads *= 2
        nb = 100*PRuby.nb_threads
        a = (0...nb).to_a
        b = (0...nb).to_a
        c = effectuer_appel somme, a, b, nb
        c.must_equal somme_tableaux_seq(a, b)
      end
    end
  end
end
