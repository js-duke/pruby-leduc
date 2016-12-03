$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'sommation_tableau'

describe "sommation_tableau" do
  [:sommation_tableau_rec,
   :sommation_tableau_rec_future,
   :sommation_tableau_tranche,
   :sommation_tableau_adjacents,
   :sommation_tableau_cyclique,
   :sommation_tableau_preduce,
  ].each do |sommation|

    describe "#{sommation}" do

      it "retourne 0 quand vide" do
        sommation_tableau_rec( [] ).must_equal 0
      end

      it "l'element quand il est unique" do
        sommation_tableau_rec( [99] ).must_equal 99
      end

      it "la somme des elements quand plus qu'un" do
        sommation_tableau_rec( [1, 20, 300, 4000] ).must_equal 4321
      end

      it "retourne 0 quand vide" do
        r = send sommation, []
        r.must_equal 0
      end

      it "la somme des elements quand plus qu'un" do
        PRuby.nb_threads = 3
        r = send sommation, [1, 20, 300]
        r.must_equal 321
      end

      it "retourne la somme de peu d'elements" do
        PRuby.nb_threads = 3
        nb = 3
        a = (0...nb).to_a
        r = send sommation, a
        r.must_equal nb * (nb-1) / 2
      end

      it "retourne la somme de beaucoup d'elements" do
        PRuby.nb_threads = 10
        nb = 100
        a = (0...nb).to_a
        r = send sommation, a
        r.must_equal nb * (nb-1) / 2
      end

      it "retourne la somme de beaucoup beaucoup d'elements" do
        PRuby.nb_threads = 3
        nb = 3*501
        a = (0...nb).to_a
        r = send sommation, a
        r.must_equal nb * (nb-1) / 2
      end
    end
  end
end
