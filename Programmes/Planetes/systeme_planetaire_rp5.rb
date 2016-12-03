$LOAD_PATH.unshift('~/pruby/lib')
require 'systeme_planetaire'

#########################################
# Le systeme specifique a simuler.
#########################################

def systeme_a_simuler
  if ENV['SYSTEME']
    systeme = ENV['SYSTEME'].to_sym
    DBC.assert [:sp2, :sp3, :sp9, :terre_lune].include?(systeme)
    return systeme
  end

  :terre_lune
end

#########################################
# Quelques systemes simples a simuler.
#########################################

def sp9
  [Planete.new( "P001", 2, 10E+15, Vector[5E+8, 1E+8], Vector[100, 100] ),
   Planete.new( "P002", 20, 100+22, Vector[3E+8, 2E+8], Vector[100, 60] ),
   Planete.new( "P003", 4, 20E+15, Vector[4E+8, 4E+8], Vector[100, -100] ),
   Planete.new( "P004", 4, 20E+15, Vector[9E+8, 3E+8], Vector[-100, 100] ),
   Planete.new( "P005", 5, 20E+15, Vector[7E+8, 4E+8], Vector[0, 0] ),
   Planete.new( "P006", 5, 20E+15, Vector[8E+8, 6E+8], Vector[0, 100] ),
   Planete.new( "P007", 2, 10E+15, Vector[13E+8, 6E+8], Vector[100, 0] ),
   Planete.new( "P008", 10, 50E+20, Vector[11E+8, 7E+8], Vector[10, 0] ),
   Planete.new( "P009", 3, 15E+15, Vector[12E+8, 9E+8], Vector[0, 10] ),
  ]
end

def sp2
  [Planete.new( "P0", 15, 1E+6, Vector[50, 50], Vector[0,0] ),
   Planete.new( "P1", 30, 1E+6, Vector[500, 500], Vector[0,0] )
  ]
end

def sp3
  [Planete.new( "P1", 10, 10E+15, Vector[5E+8, 1E+8], Vector[-100, 0] ),
   Planete.new( "P2", 20, 50E+20, Vector[3E+8, 2E+8], Vector[10, 10] ),
   Planete.new( "P3", 15, 15E+15, Vector[4E+8, 4E+8], Vector[-100, -170] )
  ]
end

def terre_lune
  # Terre : 5.9736E+24 kg
  # Lune  : 7.3490E+22 kg
  # Distance terre-lune = 3.84402000478108E+8 m = 384402000.478108 m
  # Vitesse lune = 3683 km/h
  #              = 3.683E+6/3600 m/s
  #              = 1023.06 m/s

  [Planete.new( "TERRE", 50, 5.9736E+24,
                Vector[768804000.96, 768804000.96],
                Vector[0, 0] ),
   Planete.new( "LUNE", 10, 7.3490E+22,
                Vector[768804000.96, 1153206001.43],
                Vector[1023.06, 0] )
  ]
end


#############################################################################
# Le code de traitement pour Processing
#############################################################################

# Alias pour eviter les messages d'avertissement (overloading).
java_alias :background_int, :background, [Java::int]
java_alias :color_int, :color, [Java::int, Java::int, Java::int]


# La taille de l'ecran -- pour ma machine Linux a la maison.
TAILLE = 1000

# Dessin d'une planete.
#
def draw_planete( p )
  @couleurs ||= {}
  @couleurs[p] ||= [rand(255), rand(255), rand(255)]

  stroke 0, 0, 0
  fill *@couleurs[p]

  pos = @facteur_contraction * p.position
  ellipse pos[0], pos[1], p.taille, p.taille
end

# Initialisation de Processing pour le systeme planetaire a simuler.
#
def setup
  size TAILLE, TAILLE
  background_int 255
  smooth

  @nb_iterations = 1
  @periode = 1000
  *planetes = send systeme_a_simuler
  @sys = SystemePlanetaire.new( *planetes )
  @facteur_contraction = facteur_contraction( @sys )
end

# Dessin du systeme planetaire.
def draw
  background_int 200

  @sys.planetes.each do |p|
    draw_planete( p )
    @sys.simuler( @nb_iterations, @periode )
  end
end

def facteur_contraction( sys )
  max_dist = sys.planetes.map { |p| [p.position[0], p.position[1]] }.flatten.max
  0.6 * TAILLE / max_dist
end

def mouse_pressed
  @periode *= 2
end

def key_pressed
  if key == '+'
    @nb_iterations *= 2
  elsif key == '-'
    @nb_iterations /= 2 unless @nb_iterations == 1
  elsif key == ' '
    @periode /= 2 unless @periode == 1
  end
end
