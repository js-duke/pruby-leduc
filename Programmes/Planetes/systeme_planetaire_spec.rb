$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'planete'
require_relative 'systeme_planetaire'
require_relative 'spec_helper'

describe SystemePlanetaire do
  zero = Vector[0.0, 0.0]

  describe "#clone" do
    before do
      planetes = [Planete.new( "P1", 0, 10E+15, Vector[1E+10, 0], Vector[1E+100, 0] ),
                  Planete.new( "P2", 0, 10E+15, Vector[0, 1E+10], Vector[1E+100, 0] )]
      @sys1 = SystemePlanetaire.new( *planetes )
      @sys2 = @sys1.clone
    end

    it "a une identite differente" do
      refute @sys1.equal?(@sys2)
    end

    it "a des planetes avec des identites differentes" do
      @sys1.planetes.each_index do |i|
        refute @sys1[i].equal?(@sys2[i])
      end
    end

    it "a des planetes avec les memes attributs" do
      @sys1.planetes.each_index do |i|
        assert_equal @sys2[i].nom, @sys1[i].nom
        assert_equal @sys2[i].taille, @sys1[i].taille
        assert_in_delta @sys1[i].masse, @sys2[i].masse
        assert_vector_in_delta @sys1[i].position, @sys2[i].position
        assert_vector_in_delta @sys1[i].vitesse, @sys2[i].vitesse
      end
    end
  end

  describe "#simuler" do
    context "systeme avec une planete" do
      context "au repos" do
        p = Planete.new( "P001", 0, 1.0E+10, zero, zero )
        s = SystemePlanetaire.new( p )

        it "reste au repos pour 1 iteration de temps 1" do
          s.simuler( 1, 1 )
          assert_vector_in_delta zero, p.position
          assert_vector_in_delta zero, p.vitesse
        end

        it "reste au repos pour 100 iterations de temps 1000" do
          s.simuler( 100, 1000 )
          assert_vector_in_delta zero, p.position
          assert_vector_in_delta zero, p.vitesse
        end
      end

      context "en mouvement sans force" do
        K = 97
        vit = Vector[K, K]
        LONGUE_PERIODE = 76
        NB_ITERATIONS = 17

        let (:p) { Planete.new( "P001", 0, 1.0E+10, zero, vit ) }
        let (:s) { SystemePlanetaire.new( p ) }

        it "change de position mais pas de vitesse pour 1 iteration de temps 1" do
          s.simuler( 1, 1 )
          assert_vector_in_delta Vector[K, K], p.position
          assert_vector_in_delta vit, p.vitesse
        end

        it "change de position mais pas de vitesse pour 1 iteration de temps #{LONGUE_PERIODE}" do
          s.simuler( 1, LONGUE_PERIODE )
          assert_vector_in_delta LONGUE_PERIODE * Vector[K, K], p.position
          assert_vector_in_delta vit, p.vitesse
        end

        it "change de position mais pas de vitesse pour #{NB_ITERATIONS} iterations de temps 1" do
          s.simuler( NB_ITERATIONS, 1 )
          assert_vector_in_delta NB_ITERATIONS * Vector[K, K], p.position
          assert_vector_in_delta vit, p.vitesse
        end
      end
    end

    context "petit systeme a deux planetes" do
      it "a les memes effets pour nb_iterations * periode constant" do
        v1000 = Vector[0, 1000]
        masse = 1.0E+10

        s0  = SystemePlanetaire.new( Planete.new( "P0", 0, masse, zero, zero ),
                                     Planete.new( "P2", 0, masse, v1000, zero ) )
        s1 = s0.clone
        s2 = s0.clone

        s0.simuler( 1, 9 )
        s1.simuler( 3, 3 )
        s2.simuler( 9, 1 )

        assert_systeme_planetaire_in_delta s0, s1
        assert_systeme_planetaire_in_delta s0, s2
      end
    end

    context "petit systeme avec plusieurs planetes" do
      N = 10
      vs = Array.new(N) { |i| Vector[100*i, 100*i] }
      ps = Array.new(N) { |i| Vector[i*1E+5, i*1E+5] }

      let(:ps1) { Array.new(N) { |i| Planete.new(i.to_s, 0, (i+1)*1.0E+10, ps[i], vs[i]) } }
      let(:ps2) { Array.new(N) { |i| Planete.new(i.to_s, 0, (i+1)*1.0E+10, ps[i], vs[i]) } }

      it "se comporte de la meme facon peu importe l'ordre des planetes" do
        s1 = SystemePlanetaire.new( *ps1 )
        s2 = SystemePlanetaire.new( ps2[3], ps2[4], ps2[6], ps2[0], ps2[9], ps2[1], ps2[5], ps2[7], ps2[8], ps2[2] )

        s1.simuler( 100, 1000 )
        s2.simuler( 100, 1000 )

        (0...N).each do |i|
          assert_planete_in_delta ps1[i], ps2[i]
        end
      end

      context "auquel on ajoute une planete sans masse" do
        it "se comporte de la meme facon" do
          ps2 << Planete.new( "", 0, 0, 2*ps2.last.position, 2*ps2.last.vitesse )

          s1 = SystemePlanetaire.new( *ps1 )
          s2 = SystemePlanetaire.new( *ps2 )

          s1.simuler( 1, 100 )
          s2.simuler( 1, 100 )

          (0...N).each do |i|
            assert_planete_in_delta ps1[i], ps2[i]
          end
        end
      end

      context "auqual on ajoute une autre planete" do
        it "change les vitesses uniquement selon la nouvelle planete ajoutee" do
          DT = 1000

          ps1A = Array.new(N) { |i| Planete.new("", 0, (i+1)*1.0E+15, ps[i], vs[i] ) }

          ps2 << Planete.new( "", 0, (N)*1.0E+15, 2*ps.last, zero )

          ps2A = Array.new(N) { |i| Planete.new("", 0, (i+1)*1.0E+15, ps[i], vs[i] ) }
          ps2A << Planete.new( "", 0, (N)*1.0E+15, 2*ps.last, zero )

          s1 = SystemePlanetaire.new( *ps1 )
          s2 = SystemePlanetaire.new( *ps2 )

          s1.simuler( 1, DT )
          s2.simuler( 1, DT )

          s1.planetes.each_index do |i|
            f = ps1A[i].force_de( ps2A.last )
            a = (1.0 / ps1A[i].masse) * f
            dv = DT * a
            assert_vector_in_delta dv, (ps2[i].vitesse-ps1[i].vitesse)
          end
        end
      end
    end
  end
end
