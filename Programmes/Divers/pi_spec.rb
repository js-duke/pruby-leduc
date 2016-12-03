$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'pi'

VRAI_PI = 3.1415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938

include Pi

[:monte_carlo, :monte_carlo_imperatif, :monte_carlo_peach, :monte_carlo_pmap, :monte_carlo_preduce,
 :integration1, :integration2].each do |calculer_pi|
  [2, 4, 7].each do |nb_threads|

    describe "calculer_pi -- methode #{calculer_pi} avec #{nb_threads} threads" do
      let(:delta1) { 0.0002 }
      let(:delta2) { ([:monte_carlo, :monte_carlo_imperatif, :monte_carlo_peach, :monte_carlo_pmap, :monte_carlo_preduce].include? calculer_pi) ? 0.02 : 0.0002 }

      it "produit une mauvaise approximation lorsque le nombre de points est petit" do
        pi = send calculer_pi, 28, nb_threads  # Divisiable par 2, 4, et 7

        refute_in_delta pi, VRAI_PI, delta1
      end

      it "produit une bonne approximation lorsque le nombre de points est grand" do
        pi = send calculer_pi, 100000, nb_threads

        assert_in_delta pi, VRAI_PI, delta2
      end
    end
  end
end
