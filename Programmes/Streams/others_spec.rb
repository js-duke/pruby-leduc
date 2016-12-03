$LOAD_PATH.unshift('../../spec')

EXAMPLE = true #&& false

require 'spec_helper'
require 'pruby'

describe "Various other examples" do
  describe "#stateful" do
    it "retourne les sommes cumulatives sans le 0 initial" do
      cumulate_total = lambda do |total, x|
        [ total + x, total + x ]
      end

      PRuby::Stream.source( [10, 20, 30, 40] )
        .stateful( initial_state: 0,
                   &cumulate_total )
        .to_a
        .must_equal [10, 30, 60, 100]
    end

    it "retourne les sommes cumulatives" do
      cumulate_total = lambda do |total, x|
        [ total + x, total ]
      end

      PRuby::Stream.source( [10, 20, 30, 40] )
        .stateful( initial_state: 0,
                   at_eos: -> total { total },
                   &cumulate_total )
        .to_a
        .must_equal [0, 10, 30, 60, 100]
    end
  end

  describe "#ff_node" do
    it "saute les elements pairs" do
      PRuby::Stream.source( [1, 2, 3, 4] )
        .ff_node do |x|
           if x % 2 == 0
             x
           else
             PRuby::GO_ON
           end
         end
        .to_a
        .must_equal [2, 4]
    end

    it "fait un petit calcul du style de celui qu'on trouve dans le tutoriel" do
      PRuby::Stream.source([10])
        .ff_node do |n, out_channel|
           for k in 1..n
             out_channel << k
           end
           PRuby::EOS
         end
        .ff_node { |x| x * 10 }
        .to_a
        .must_equal (1..10).map { |x| x * 10 }
    end

    it "retourne le bon resultat lorsque rien a faire a la fin" do
      PRuby::Stream.source( [10, 20, 30, 40] )
        .ff_node_with_state do |state, x|
           if state.nil?
             [x, PRuby::GO_ON]  # Wait for second number
           else
             [nil, state + x]
           end
         end
        .to_a
        .must_equal [30, 70]
    end
  end

  describe "#go" do
    it "prend deux elements a la fois pour en generer un seul" do
      PRuby::Stream.source( [10, 20, 30, 40] )
        .go do |cin, cout|
          while (v1 = cin.get) != PRuby::EOS
            cout << v1 + cin.get
          end
         end
        .to_a
        .must_equal [30, 70]
    end
  end

  describe "#apply" do
    it "retourne le stream resultant de l'application du bloc" do
      plus_2 = lambda { |s| s.map { |x| x + 1 }.map { |x| x + 1 } }
      take_2 = lambda { |s| s.take(2) }

      PRuby::Stream.source( [10, 20, 30, 40] )
        .apply( &plus_2 )
        .apply( &take_2 )
        .to_a
        .must_equal [12, 22]
    end

    it "retourne le stream resultant de la concatenation de lambdas" do
      plus_2 = lambda { |s| s.map { |x| x + 1 }.map { |x| x + 1 } }
      take_2 = lambda { |s| s.take(2) }

      (PRuby::Stream.source( [10, 20, 30, 40] ) >> plus_2 >> take_2)
        .to_a
        .must_equal [12, 22]
    end
  end
end
