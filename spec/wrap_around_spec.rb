require_relative 'spec_helper'
require 'pruby'

describe PRuby do
  describe ".pipeline" do
    NB_NODES = 3

    describe "#wrap_around!" do
      it "traite le probleme de l'anneau pour le calcul du min" do
        def node( i, v )
          lambda do |cin, cout|
            cout << [v, 0] if i == 0  # Amorce de la 1ere passe.

            le_min, de_qui = cin.get
            if v < le_min
              le_min = v
              de_qui = i
            end
            cout << [le_min, de_qui]

            unless i == 0
              le_min, de_qui = cin.get
              cout << [le_min, de_qui] if i < NB_NODES-1 # Sauf le dernier!
            end

            # On retourne le resultat (pour les tests).
            [le_min, de_qui]
          end
        end

        vs = Array.new(NB_NODES).map{ rand }

        #
        # Autre facon: p = PRuby.pipeline *((0...NB_NODES).map { |i| node(i, vs[i]) })
        #
        pipe = PRuby.pipeline node( 0, vs[0] )
        (1...NB_NODES).each do |i|
          pipe.add_stage node( i, vs[i] )
        end
        pipe.wrap_around!.run

        res_run = pipe.value

        # On verifie les resultats
        mins = res_run.map &:first
        quis = res_run.map &:last

        # Tous les mins sont eqaux au vrai min
        mins.all? { |mi| mi == vs.min }.must_equal true

        # Tous ont retourne la meme position pour le minimum
        quis.all? { |qui| qui == quis.first }.must_equal true

        # La position retourne est bien le min
        vs[quis.first].must_equal vs.min
      end
    end


    it "traite le probleme de l'anneau pour le calcul du min et du max" do
      def node( i )
        lambda do |cin, cout|
          v = rand

          cout << [v, v] if i == 0 # Amorce de la 1ere passe.

          le_min, le_max = cin.get
          le_min = [le_min, v].min
          le_max = [le_max, v].max
          cout << [le_min, le_max]

          unless i == 0
            le_min, le_max = cin.get
            cout << [le_min, le_max] if i < NB_NODES-1 # Sauf pour le dernier!
          end

          # On retourne le resultat (pour les tests).
          [le_min, le_max]
        end
      end

      mins = Array.new(NB_NODES)
      maxs = Array.new(NB_NODES)

      pipe = (PRuby.pipeline *(0...NB_NODES).map { |i| node(i) })
      pipe.wrap_around!.run

      res_run = pipe.value

      # On verifie les resultats
      mins = res_run.map &:first
      maxs = res_run.map &:last

      mins.first.must_equal mins.min
      maxs.first.must_equal maxs.max

      mins.all? { |m| m == mins.first }.must_equal true
      maxs.all? { |m| m == maxs.first }.must_equal true
    end
  end
end
