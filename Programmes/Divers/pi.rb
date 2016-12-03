$LOAD_PATH.unshift('~/prby/lib')
require 'pruby'

#
# Programme qui calcule la valeur de pi.
#
# Diverses methodes sont utilisees:
#
# ** integration numerique: la valeur de pi est obtenue en calculant
#    l'integrale (par l'intermediaire d'une approximation numerique)
#    de la fonction 4/(x^2 + 1) entre les bornes 0.0 et 1.0.
#
#    La methode utilisee est celle basee sur une quadrature composite
#    de deuxieme ordre (mais non adaptative), donc utilisant la
#    methode des trapezes.
#
#    Deux approches de programmation sont aussi utilises:
#    - peach sur les index des rectangles
#    - pmap sur les index des numeros de thread
#
# ** monte carlo: methode de la cible circulaire inscrite dans un
#    carre.
#

module Pi

  def integration1( nb_rectangles = 100, nb_threads = PRuby.nb_threads )
    def f( x )
      4.0 / ( 1.0 + x * x )
    end

    a = 0.0
    b = 1.0
    h = (b - a) / nb_rectangles   # Taille du pas d'integration.

    sommes = Array.new( nb_threads ) { 0.0 }
    (0...nb_rectangles).peach( nb_threads: nb_threads ) do |i|
      gauche = a + i * h
      droite = gauche + h
      sommes[PRuby.thread_index] += ( f(gauche) + f(droite) ) * h / 2
    end

    sommes.reduce( &:+ )
  end

  def integration2( nb_rectangles = 100, nb_threads = PRuby.nb_threads )
    def f( x )
      4.0 / ( 1.0 + x * x )
    end

    a = 0.0
    b = 1.0
    h = (b - a) / nb_rectangles   # Taille du pas d'integration.

    nb_rectangles /= nb_threads   # nb_rectangles a calculer pour chaque thread.

    sommes = (0...nb_threads).map do |k|
      PRuby.future do
        mon_a = a + k * nb_rectangles * h
        somme = 0.0
        (0...nb_rectangles).each do |i|
          gauche = mon_a + i * h
          droite = gauche + h
          somme += ( f(gauche) + f(droite) ) * h / 2
        end
        somme
      end
    end

    sommes.map( &:value ).reduce( &:+ )
  end


  # Pas tres precis. Et si on augmente beaucoup le nombre de
  # lancers... pas tres rapide :(
  #@@@/monte_carlo/evaluer_pi/
  def nb_dans_cercle_seq( nb_lancers )
    nb = 0
    nb_lancers.times do
      # On genere un point aleatoire.
      x, y = rand, rand

      # On incremente s'il est dans le cercle
      nb += 1 if x * x + y * y <= 1.0
    end

    nb
  end

  def monte_carlo( nb_lancers, nb_threads = PRuby.nb_threads )
    # On active les divers threads en creant des futures.
    futures_nb_dans_cercle = (0...nb_threads).map do
      PRuby.future { nb_dans_cercle_seq(nb_lancers/nb_threads) }
    end

    # On recoit et on additionne les resultats des futures.
    nb_total_dans_cercle =
      futures_nb_dans_cercle
      .map( &:value )
      .reduce( &:+ )

    4.0 * nb_total_dans_cercle / nb_lancers
  end
  #@@@

  #@@@/monte_carlo_imperatif/evaluer_pi/
  def monte_carlo_imperatif( nb_lancers, nb_threads = PRuby.nb_threads )
    # On active les threads en creant des futures.
    futures_nb_dans_cercle = []
    nb_threads.times do
      futures_nb_dans_cercle << PRuby.future do
        nb_dans_cercle_seq( nb_lancers / nb_threads )
      end
    end

    # On recoit les resultats des futures.
    les_nbs = []
    futures_nb_dans_cercle.each do |f|
      les_nbs << f.value
    end

    # On additionne les resultats intermediaires.
    nb_total_dans_cercle = 0
    les_nbs.each do |nb|
      nb_total_dans_cercle += nb
    end

    4.0 * nb_total_dans_cercle / nb_lancers
  end
  #@@@

  #@@@/monte_carlo_peach/evaluer_pi/
  def monte_carlo_peach( nb_lancers, nb_threads = PRuby.nb_threads )
    nb_dans_cercle = Array.new( nb_threads )

    (0...nb_threads).peach( nb_threads: nb_threads ) do |k|
      nb_dans_cercle[k] =
         nb_dans_cercle_seq(nb_lancers / nb_threads)
    end

    nb_total_dans_cercle = nb_dans_cercle.reduce( &:+ )

    4.0 * nb_total_dans_cercle / nb_lancers
  end
  #@@@

  #@@@/monte_carlo_pmap/evaluer_pi/
  def monte_carlo_pmap( nb_lancers, nbt = PRuby.nb_threads )
    nb_dans_cercle = (0...nbt).pmap(nb_threads: nbt) do
      nb_dans_cercle_seq( nb_lancers / nbt )
    end

    nb_total = nb_dans_cercle.reduce( &:+ )

    4.0 * nb_total / nb_lancers
  end
  #@@@

  #@@@/monte_carlo_preduce/evaluer_pi/
def monte_carlo_preduce( nb_lancers, nbt = PRuby.nb_threads )
  total = (0...nbt)
            .preduce(0, nb_threads: nbt) do |nb, _numt|
    nb + nb_dans_cercle_seq( nb_lancers / nbt )
  end

  4.0 * total / nb_lancers
end
  #@@@
end
