$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'planete'

describe Planete do
  describe ".initialize" do
    it "cree une planete et definit ses attributs" do
      nom = "P1"
      taille = 0
      masse = 1.0E+6
      position = Vector[10, 10]
      vitesse = Vector[0, 0]

      p1 = Planete.new( nom, taille, masse, position, vitesse )

      p1.nom.must_equal nom
      p1.taille.must_equal taille
      p1.masse.must_equal masse
      assert_vector_in_delta p1.position, position
      assert_vector_in_delta p1.vitesse, vitesse
    end
  end

  context "differentes planetes pour tester distance et force_de" do
    P1 =
      [Planete.new( "P1.0", nil, 1.0E+6, Vector[10.0, 10.0], nil ),
       Planete.new( "P1.1", nil, 1.0E+6, Vector[0.0, 100.0], nil ),
       Planete.new( "P1.2", nil, 1.0E+6, Vector[0.0, 0.0], nil ),
       Planete.new( "P1.3", nil, 1.0E+6, Vector[0.0, 0.0], nil ),
       Planete.new( "P1.4", nil, 1.0E+6, Vector[0.0, 0.0], nil ),
       Planete.new( "P1.5", nil, 0.0, Vector[0.0, 0.0], nil ),
     ]

    P2 =
      [Planete.new( "P2.0", nil, 1.0E+6, Vector[-10.0, -10.0], nil ),
       Planete.new( "P2.1", nil, 1.0E+8, Vector[0.0, -300.0], nil ),
       Planete.new( "P2.2", nil, 1.0E+8, Vector[0.0, 200.0], nil ),
       Planete.new( "P2.3", nil, 1.0E+8, Vector[0.0, 400.0], nil ),
       Planete.new( "P2.4", nil, 1.0E+7, Vector[2000.0, 0.0], nil ),
       Planete.new( "P2.5", nil, 1.0E+7, Vector[2000.0, 0.0], nil ),
      ]

    DIST =
      [ 28.2842,
        400.0,
        200.0,
        400.0,
        2000.0,
        2000.0,
      ]

    F2_SUR_1 =
      [Vector[-0.0590, -0.0590],
       Vector[0.0000, -0.0417],
       Vector[0.0, 0.1668],
       Vector[0.0, 0.0417],
       Vector[0.00017, 0.0],
       Vector[0.0, 0.0],
      ]

    P1.each_index do |k|
      p1 = P1[k]
      p2 = P2[k]

      describe "#{p1}.#distance( #{p2} )" do
        dist_p1_p2 = DIST[k]
        it "retourne la bonne distance dans l'espace 2D" do
          assert_in_delta dist_p1_p2, p1.distance(p2)
        end
      end

      describe "#{p1}.#force_de( #{p2} )" do
        f2sur1 = F2_SUR_1[k]

        it "retourne la force directe" do
          assert_vector_in_delta f2sur1, p1.force_de(p2)
        end

        it "retourne la force inverse quand on change l'ordre" do
          assert_vector_in_delta (-1 * f2sur1), p2.force_de(p1)
        end
      end
    end

    describe "#deplacer" do
      context "selon une force strictement verticale pour differentes durees" do
        planetes =
          [Planete.new( "P1", 0, 1.0E+6, Vector[0, 0], Vector[0, 0] ),
           Planete.new( "P2", 0, 1.0E+8, Vector[0, 0], Vector[0, 0] ),
           Planete.new( "P3", 0, 1.0E+8, Vector[0, 0], Vector[0, 0] ),
          ]

        forces =
          [Vector[0, 1E+6],
           Vector[0, 1E+26],
           Vector[0, -1E+26],
          ]

        planetes.each_index do |k|
          [1, 13, 87].each do |nb|
            p = planetes[k]
            force = forces[k]
            context "calcule le deplacement de #{p} pour #{nb} etape(s)" do
              p_ = p.clone
              p_.deplacer( force, nb )

              it "assure que rien ne change au niveau des x" do
                assert_in_delta 0.0, p_.position[0]
                assert_in_delta 0.0, p_.vitesse[0]
              end

              it "verifie les Modifications au niveau des y" do
                facteur1 = force[1] / p_.masse
                assert_in_delta nb**2 * 0.5 * facteur1, p_.position[1]
                assert_in_delta nb * facteur1, p_.vitesse[1]
              end
            end
          end
        end
      end

      context "selon differentes forces pour 10 unites de temps" do
        planetes =
          [Planete.new( "P0", 0, 1E+8, Vector[0, 100], Vector[0, 10] ),
           Planete.new( "P1", 0, 1E+8, Vector[0, 100], Vector[0, 100] ),
           Planete.new( "P2", 0, 1E+8, Vector[0, 100], Vector[0, -100] ),
           Planete.new( "P3", 0, 1E+8, Vector[100, 0], Vector[-1000, -1000] ),
          ]

        forces =
          [Vector[1E+10, 0],
           Vector[0, -1E+10],
           Vector[1E+11, 1E+10],
           Vector[-1E+10, -1E+11],
          ]

        positions =
          [Vector[5000.0, 200.0],
           Vector[0.0, -3900.0],
           Vector[50000.0, 4100.0],
           Vector[-14900.0, -60000.0],
          ]

        vitesses =
          [Vector[1000.0, 10.0],
           Vector[0.0, -900.0],
           Vector[10000.0, 900.0],
           Vector[-2000.0, -11000.0],
          ]

        planetes.each_index do |k|
          it "calcule le deplacement pour 10 unites de temps" do
            p = planetes[k]
            p.deplacer( forces[k], 10 )
            assert_vector_in_delta positions[k], p.position
            assert_vector_in_delta vitesses[k], p.vitesse
          end
        end
      end
    end
  end
end
