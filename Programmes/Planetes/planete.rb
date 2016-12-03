$LOAD_PATH.unshift('~/pruby/lib')

require 'matrix'
require 'vector'

# Classe modelisant une planete.
#
#  Pour plus de details, des explications sur ce genre de calculs sont
#  presentes dans l'article "The approximation tower in computational
#  science: Why testing scientific software is difficult", K. Hinsen,
#  Computing in Science & Engineering Volume 17, Issue 4, p. 72-77.
#  http://ieeexplore.ieee.org/xpl/articleDetails.jsp?arnumber=7131419
#
class Planete
  # La constante de gravitation universelle.
  # https://fr.wikipedia.org/wiki/Constante_gravitationnelle
  G = 6.67384E-11 # m**3 kg**-1 s**-2;

  #####################################################################
  # Constructeurs et attributs.
  #####################################################################

  # Constructeur d'un objet Planete.
  #
  # @param [String] nom
  # @param [Fixnum] taille
  # @param [Float] masse
  # @param [Vector] position
  # @param [Vector] vitesse
  #
  # @require taille > 0
  #
  def initialize( nom, taille, masse, position, vitesse )
    @nom = nom # String
    @taille = taille # Fixnum
    @masse = masse # Float
    @position = position # Vector
    @vitesse = vitesse # Vector
  end

  # Nom de la planete.
  #
  # @return [String]
  #
  attr_reader :nom


  # Masse de la planete, en kg.
  #
  # @return [Float]
  #
  attr_reader :masse

  # Position dans l'espace 2D, sous forme vectorielle.
  #
  # @return [Vector]
  #
  attr_reader :position

  # Vitesse de deplacement, sous forme vectorielle.
  #
  # @return [Vector]
  #
  attr_reader :vitesse


  # Taille pour l'affichage.
  #
  # @return [Fixnum]
  #
  # Taille pour l'affichage, avec Processing.  Le rapport entre les
  # tailles n'est pas necessairement le meme que celui entre les
  # masses... parce que sinon cela pourrait etre trop petit pour
  # s'afficher correctement a l'ecran.
  #
  attr_reader :taille

  # Chaine representant la planete.
  #
  # @return [String]
  #
  def to_s
    nom
  end

  #####################################################################
  # Methodes.
  #####################################################################

  # Force exercee par la planete p.
  #
  # @note p1.force_de( p2 ) = -1 * p2.force_de( p1 )
  #
  # @return [Vector]
  #
  def force_de( p )
    dist = (position - p.position).magnitude
    f = ( G * masse * p.masse ) / ( dist * dist )

    (f / dist) * (p.position - position)
  end


  # Deplace la planete en fonction de la force et du temps.
  #
  # @param [Vector] force
  # @param [Float] dt intervalle de temps
  #
  # @require dt > 0.0
  #
  # @return [self]
  #
  def deplacer( force, dt )
    # Acceleration : F = ma => a = F/m
    acc = force / masse

    # Changement de vitesse durant l'intervalle.
    dvit = dt * acc

    # Changement de position: on prend la vitesse au milieu de
    # l'intervalle, i.e., moyenne entre la vitesse au debut et vitesse
    # a la fin:  vit + (vit + dvit)) / 2 = vit + dvit/2
    vitmoy = vitesse + 0.5 * dvit
    dpos = dt * vitmoy

    # Mise a jour de la vitesse et de la position.
    @vitesse += dvit
    @position += dpos

    self
  end

  # Distance par rapport a une autre planete.
  #
  # @param [Planete] autre
  #
  # @return [Vector] distance entre self et autre
  #
  def distance( autre )
    position.distance(autre.position)
  end
end
