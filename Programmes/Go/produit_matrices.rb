$LOAD_PATH.unshift('~/pruby/lib')

require 'pruby'

class ProduitMatrices
  def self.travailleur
    lambda do |donnees, resultats|
      # On obtient les donnees a traiter.
      a = donnees.get  # Tranche de a.
      b = donnees.get  # Matrice b au complet.

      # On alloue l'espace pour la tranche resultante.
      c = Array.new(a.size) { Array.new(b.size) }

      # On calcule la tranche.
      (0...a.size).each do |i|
        (0...b.size).each do |j|
          c[i][j] = (0...b.size).reduce(0) { |s, k| s + a[i][k] * b[k][j] }
        end
      end

      # On retourne la tranche calculee au processus maitre.
      resultats.put c
    end
  end

  def self.bornes_tranche( k, n, nb_procs )
    b_inf = n / nb_procs * k
    b_sup = b_inf + n / nb_procs - 1
    b_inf..b_sup
  end

  #
  # Effectue le produit de a et b en utilisant exactement nb_procs
  # travailleurs.
  #
  # Preconditions (pour simplifier la presentation):
  #   a et b sont des matrices carres de meme taille
  #   nb_procs divise n, la taille des matrices
  #
  def self.run( a, b, nb_procs )
    unless a.size == b.size
      fail "*** Erreur: Matrices de tailles differentes"
    end
    unless a.size % nb_procs == 0
      fail "*** Erreur: nb_procs (#{nb_procs})
                ne divise pas a.size (#{a.size})"
    end

    # On cree les canaux.
    donnees   = Array.new( nb_procs ) { PRuby::Channel.new }
    resultats = Array.new( nb_procs ) { PRuby::Channel.new }

    # On active les travailleurs avec les canaux appropries.
    (0...nb_procs).each do |k|
      travailleur.go( donnees[k], resultats[k] )
    end

    # On transmet les donnees aux travailleurs.
    (0...nb_procs).each do |k|
      # On transmet la tranche appropriee de a... mais b au complet!
      bornes = bornes_tranche(k, a.size, nb_procs)
      donnees[k].put a[bornes]
      donnees[k].put b
    end

    # On recoit les tranches calculees par les travailleurs.
    c = Array.new(a.size) { Array.new(a.size) }
    (0...nb_procs).each do |k|
      bornes = bornes_tranche(k, a.size, nb_procs)
      c[bornes] = resultats[k].get
    end

    c
  end
end
