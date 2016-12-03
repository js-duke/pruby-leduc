$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'planete'
require_relative 'systeme_planetaire'
require_relative 'spec_helper'

#####################################################################
# Methodes auxiliaires pour les tests.
#####################################################################

# Obtient la valeur d'une variable d'environnement, sinon retourne une
# valeur par defaut.
#
def var_env( variable, defaut, conversion = lambda do |x| x.to_i end )
  ENV[variable] ? conversion.call(ENV[variable]) : defaut
end

# Genere n planetes de facon aleatoire, tant pour la masse que la
# position et la vitesse.
#
def generer_planetes( n )
  (0...n).map do |i|
    Planete.new( "#{i}", 0, rand(10E+15), rand_vector, rand_vector )
  end
end

# Genere un vecteur aleatoire.
#
def rand_vector
  Vector[rand(10E+10), rand(10E+10)]
end


#####################################################################
# Les tests eux-memes.
#####################################################################

describe SystemePlanetaire do
  NB_THREADS = var_env 'NB_THREADS', PRuby.nb_threads

  NB_ITERATIONS = var_env 'NB_ITERATIONS', 1
  DUREE_ITERATION = var_env 'DUREE_ITERATION', 10

  NB_GROS = var_env 'NB_GROS', 2
  NB_TRES_GROS = var_env 'NB_TRES_GROS', 10

  # Les divers systemes planetaires utilises pour les tests.
  SYSTEMES = {
    # Quelques systemes simples.
    sp2:
    [Planete.new( "P1", 0, 10E+15, Vector[1E+10, 0], Vector[1E+100, 0] ),
     Planete.new( "P2", 0, 10E+15, Vector[0, 1E+10], Vector[1E+100, 0] )],

    sp9:
    [Planete.new( "P1", 2, 10E+15, Vector[5E+8, 1E+8], Vector[0, 0] ),
     Planete.new( "P2", 20, 100E+15, Vector[3E+8, 2E+8], Vector[0, 0] ),
     Planete.new( "P3", 4, 20E+15, Vector[4E+8, 4E+8], Vector[0, 0] ),
     Planete.new( "P4", 4, 20E+15, Vector[9E+8, 3E+8], Vector[0, 0] ),
     Planete.new( "P5", 5, 20E+15, Vector[7E+8, 4E+8], Vector[0, 0] ),
     Planete.new( "P6", 5, 20E+15, Vector[8E+8, 6E+8], Vector[0, 0] ),
     Planete.new( "P7", 2, 10E+15, Vector[13E+8, 6E+8], Vector[0, 0] ),
     Planete.new( "P8", 10, 50E+15, Vector[11E+8, 7E+8], Vector[0, 0] ),
     Planete.new( "P9", 3, 15E+15, Vector[12E+8, 9E+8], Vector[0, 0] ),
    ],

    # Systeme terre--lune avec vraies masses et distances.
    terre_lune:
    [Planete.new( "TERRE", 50, 5.9736E+24, Vector[7.68804E+8, 7.68804E+8], Vector[0, 0] ),
     Planete.new( "LUNE", 10, 7.3490E+22, Vector[7.68804E+8, 1.153206E+9], Vector[1.023E+3, 0] )
    ],

    # Quelques systemes planetaires aleatoires.
    sp_1:
    generer_planetes( 1 ),

    sp_1:
    generer_planetes( 2 ),

    sp_3:
    generer_planetes( 3 ),

    sp_4:
    generer_planetes( 4 ),

    sp_gros:
    generer_planetes( NB_GROS ),

    sp_tres_gros:
    generer_planetes( NB_TRES_GROS ),
  }


  # Les simulations.
  #
  # On simule la version sequentielle, puis la version parallele
  # selectionnee, puis on verifie que les systemes resultants sont les
  # memes.
  #
  systemes = var_env( 'SYSTEME', SYSTEMES.keys,
                      ->(x) { [x.to_sym] } )
  modes = var_env( 'MODE', SystemePlanetaire::MODES - [:seq],
                   ->(x) { [x.to_sym] } )

  systemes.each do |planetes|
    modes
      .each do |autre_version|
      it "verifie que les versions sequentielle et #{autre_version} ont le meme resultat pour #{planetes}" do
        s1 = SystemePlanetaire.new( *SYSTEMES[planetes] )
        s2 = s1.clone

        s1.simuler( NB_ITERATIONS, DUREE_ITERATION, :seq )

        s2.nb_threads = NB_THREADS
        s2.simuler( NB_ITERATIONS, DUREE_ITERATION, autre_version )

        assert_systeme_planetaire_in_delta s1, s2
      end
    end
  end
end
