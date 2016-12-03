$LOAD_PATH.unshift('~/pruby/lib')

require 'pruby'

require_relative 'planete'

# Classe modelisant un systeme planetaire, donc un groupe de planetes
# qui vont interagir entre elles en fonction de leurs masses et leurs
# positions.
#
# Chaque planete est dotee d'une position et d'une vitesse initiale.
# L'ensemble des mouvements des planetes est ensuite simule, selon
# divers parametres.
#
class SystemePlanetaire

  #####################################################################
  # Les differents modes d'execution pour le calcul des forces et le
  # deplacement des planetes.
  #####################################################################
  #
  # Les differentes modes representent des strategies differentes
  # d'execution des deux principales methodes utilisees par la methode
  # simuler, soit celles pour le calcul des forces (calculer_forces_X)
  # et celle pour le deplacement des planetes resultant de ces forces
  # (deplacer_X).
  #

  MODES = [:seq,
           :par_fj_fin,
           :par_fj_adj,
           :par_fj_cyc,
           :par_sta,
           :par_dyn,
          ]

  MODES_AVEC_TAILLE_TACHE = [:par_fj_cyc, :par_sta, :par_dyn]

  #####################################################################
  # Parametres et methodes specifiques a des executions paralleles.
  #####################################################################

  # Nombre de threads a utiliser lors d'une operation parallele.
  #
  # Valeur par defaut = nil
  #
  # @return [nil, Fixnum]
  #
  attr_reader :nb_threads

  def nb_threads=( nbt )
    if nbt
      DBC.check_type nbt, Fixnum, "*** Nb. threads invalide = #{nbt}"
      DBC.require nbt > 0, "*** Nb. threads invalide = #{nbt}"
    end

    @nb_threads = nbt
  end

  # Taille par defaut des taches pour les approches statique/cyclique
  # et dynamique.
  TAILLE_TACHE_DEFAUT = 5


  #####################################################################
  # Constructeurs et attributs d'un systeme planetaire.
  #####################################################################

  # Initialise un systeme planetaire.
  #
  # @param [Array<Planete>] planetes une liste variable de planetes du systeme
  #
  # @ensure self.planetes == planetes && self.nb_planetes == planetes.size
  # @ensure nb_threads == PRuby.nb_threads
  #
  def initialize( *planetes )
    @planetes = planetes
    @nb_planetes = @planetes.size
    @nb_threads = PRuby.nb_threads
  end

  # Clone un systeme planetaire.
  #
  # @note Utile essentiellement pour les tests, pour comparer deux
  #   facons differentes de faire evoluer un meme systeme.
  #
  # @return [SystemePlanetaire] Systeme identique au systeme initial
  #   mais ou chaque planete a ete clonee
  #
  def clone
    planetes = @planetes.map(&:clone)
    SystemePlanetaire.new( *planetes )
  end

  # Nombre de planetes dans le systeme.
  #
  # @return [Fixnum]
  #
  attr_reader :nb_planetes

  # Liste des planetes dans le systeme.
  #
  # @return [Array<Planete>]
  #
  attr_reader :planetes

  # La i-eme planete du systeme.
  #
  # @param [Fixnum] i
  # @require 0 <= i < nb_planetes
  # @return [Planete]
  #
  def []( i )
    @planetes[i]
  end


  #####################################################################
  # Methode de simulation des interactions.
  #####################################################################

  # Simule l'evolution d'un groupe de planetes pendant un certain
  # nombre d'iterations (time steps), chacun d'une certaine duree, en
  # utilisant un mode particulier de simulation (mise en oeuvre
  # sequentielle ou parallele).
  #
  # @param [Fixnum] nb_iterations
  # @param [Float] dt temps pour chaque time step
  # @require dt > 0.0
  #
  # @return [void]
  #
  # @ensure les diverses planetes ont ete deplacees en fonction de
  # leurs interactions simulees
  #
  def simuler( nb_iterations, dt, mode = :seq, taille_tache = nil )
    DBC.require MODES.include?(mode), "*** Mode invalide = #{mode}"

    if MODES_AVEC_TAILLE_TACHE.include?(mode)
      DBC.require taille_tache.nil? || taille_tache == true || taille_tache > 0
      @taille_tache = taille_tache || TAILLE_TACHE_DEFAUT
    end

    nb_iterations.times do
      # On calcule l'ensemble des forces s'exercant sur chacune des
      # planetes (donc en fonction de toutes les autres planetes).
      forces = send "calculer_forces_#{mode}"

      # On deplace chacune des planetes selon les forces calculees.
      send "deplacer_#{mode}", forces, dt
    end
  end


  private

  #@-
  # Somme les forces exercees sur une planete a partir d'un ensemble
  # d'autres planetes.
  #
  # Cet ensemble peut inclure la planete elle-meme, donc il faut
  # l'ignorer dans le calcul des forces (avec equal?, qui compare
  # l'identite entre objets).
  #
  # @param [Planete] p la planete cible sur laquelle on veut calculer les forces
  # @param [Array<Planete>] planetes l'ensemble de planetes
  #
  # @return [Vector] la force resultante, sommation des forces
  #   exercees par chacune es autres planetes
  #
  def forces_sur_planete( p, planetes )
    planetes.reduce( Vector[0.0, 0.0] ) do |force, autre|
      if p.equal?(autre)
        force # On ignore l'effet sur elle-meme!
      else
        force + p.force_de(autre)
      end
    end
  end
  #@+

  # Calcul des forces exercees entre les diverses planetes
  #
  # @return [Array<Vector>]
  #
  # @ensure result[i] = sommes des forces exercees sur la i-eme
  #   planete par l'ensemble des autres planetes, en ignorant l'effet
  #   de la i-eme planete elle-meme.
  #
  # @note On peut utiliser equal? pour determiner si deux objets sont
  #   en fait le meme objet, i.e., equal? compare les references (les
  #   pointeurs, les identites) et non l'egalite de contenu.
  #
  def calculer_forces_seq
    #@-
    (0...nb_planetes).map do |i|
      forces_sur_planete( planetes[i], planetes )
    end
    #@+
  end

  def calculer_forces_par_fj_fin
    #@-
    futures = (0...nb_planetes).map do |i|
      PRuby.future { forces_sur_planete( planetes[i], planetes ) }
    end

    futures.map(&:value)
    #@+
  end

  #@-
  def bornes_de_tranche( num_thread, n, nb_threads )
    # Pour uniformiser le plus possible la repartition des elements
    # quand non divisible.
    nb_min_par_thread = n / nb_threads
    nb_a_distribuer = n % nb_threads

    b_inf = num_thread * nb_min_par_thread + [num_thread, nb_a_distribuer].min
    b_sup = (num_thread+1) * nb_min_par_thread + [num_thread+1, nb_a_distribuer].min - 1
    b_inf..b_sup
  end
  #@+

  def calculer_forces_par_fj_adj
    #@-
    nb_thr = [nb_threads, nb_planetes].min

    forces = Array.new( nb_planetes )
    PRuby.pcall( 0...nb_thr,
                 lambda do |num_thread|
                   bornes_de_tranche(num_thread, nb_planetes, nb_thr).each do |i|
                     forces[i] = forces_sur_planete( planetes[i], planetes )
                   end
                 end
                 )
    forces
    #@+
  end

  def calculer_forces_par_fj_cyc
    #@-
    nb_thr = [nb_threads, nb_planetes].min

    forces = Array.new( nb_planetes )
    PRuby.pcall( 0...nb_thr,
                 lambda do |num_thread|
                   (num_thread...nb_planetes).step(nb_thr).each do |k|
                     forces[k] = forces_sur_planete( planetes[k], planetes )
                   end
                 end
                 )
    forces
    #@+
  end

  def calculer_forces_par_sta
    #@-
    (0...nb_planetes).pmap( static: @taille_tache ) do |i|
      forces_sur_planete( planetes[i], planetes )
    end
    #@+
  end

  def calculer_forces_par_dyn
    #@-
    (0...nb_planetes).pmap( dynamic: @taille_tache ) do |i|
      forces_sur_planete( planetes[i], planetes )
    end
    #@+
  end


  # Deplace un groupe de planetes selon un ensemble de vecteurs de
  # force, pour une certaine periode de temps et en utilisant un mode
  # d'execution.
  #
  # @param [Array<Vector>] forces
  # @param [Float] dt temps de deplacement
  # @require dt > 0.0
  #
  # @return [void]
  #
  # @ensure La i-eme planete a ete deplacee selon la force indiquee
  #   par forces[i] pour la duree indiquee
  #
  def deplacer_seq( forces, dt )
    #-
    (0...nb_planetes).each do |i|
      planetes[i].deplacer( forces[i], dt )
    end
    #+
  end

  def deplacer_par_fj_fin( forces, dt )
    #-
    PRuby.pcall( 0...nb_planetes,
                 lambda { |i| planetes[i].deplacer( forces[i], dt ) }
                 )
    #+
  end

  def deplacer_par_fj_adj( forces, dt )
    #-
    (0...nb_planetes).peach( static: true ) do |i|
      planetes[i].deplacer( forces[i], dt )
    end
    #+
  end

  def deplacer_par_fj_cyc( forces, dt )
    #-
    nb_thr = [nb_threads, nb_planetes].min
    PRuby.pcall( 0...nb_thr,
                 lambda do |num_thread|
                   (num_thread...nb_planetes).step(nb_thr).each do |k|
                     planetes[k].deplacer( forces[k], dt )
                   end
                 end
                 )
    #+
  end

  def deplacer_par_sta( forces, dt )
    #-
    (0...nb_planetes).peach( static: @taille_tache ) do |i|
      planetes[i].deplacer( forces[i], dt )
    end
    #+
  end

  def deplacer_par_dyn( forces, dt )
    #-
    (0...nb_planetes).peach( dynamic: @taille_tache ) do |i|
      planetes[i].deplacer( forces[i], dt )
    end
    #+
  end
end
