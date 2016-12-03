$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

#@@@/wc_seq/wc/
def wc_seq( fichs )
  fichs.map { |fich| wc1( fich ) }
end
#@@@

#@@@/wc_pmap/wc/
# Compte le nombre de mots dans une ligne.
def nb_mots( ligne )
  ligne.strip.split(/\s+/).size
end

# Version Ruby de wc qui traite un (1) fichier.
def wc1( fich )
  lignes = IO.readlines( fich )

  nb_lignes = lignes.size
  nb_mots   = lignes.map { |l| nb_mots(l) }.reduce(0, &:+)
  nb_cars   = lignes.map(&:size).reduce(0, &:+)

  [nb_lignes, nb_mots, nb_cars, fich]
end


# Fonction qui applique wc sur une liste de fichiers.
def wc_pmap( fichs )
  fichs.pmap { |fich| wc1( fich ) }
end
#@@@

#@@@/wc_cyclique/wc/
def wc_cyclique( fichs )
  fichs.pmap( static: 2 ) { |fich| wc1( fich ) }
end
#@@@/wc_cyclique/wc/

#@@@/wc_dynamique/wc/
def wc_dynamique( fichs )
  fichs.pmap( dynamic: 2 ) { |fich| wc1( fich ) }
end
#@@@

def wc_sac_taches_future( fichs, taille_tache = 3 )
  # On alloue le tableau pour les resultats.
  res = Array.new(fichs.size)

  # On utilise autant de travailleurs que de threads.
  nb_travailleurs = PRuby.nb_threads

  # On cree le sac de taches et y on met les taches.
  sac_taches = PRuby::TaskBag.new( nb_travailleurs )
  (0...fichs.size).step(taille_tache) do |i|
    sup = [i + taille_tache - 1, fichs.size - 1].min
    sac_taches.put i..sup
  end

  # On active les travailleurs.
  futures = (0...nb_travailleurs).map do
    PRuby.future do
      while taches = sac_taches.get
        taches.each do |i|
          res[i] = wc1( fichs[i] )
        end
      end
    end
  end

  # On attend que les travailleurs terminent.
  futures.map(&:value) # Valeur retournee non-significative.

  # On retourne le resultat.
  res
end

# Remarque concernant le code ci-bas:
#
# La version initiale utilisait le segment de code suivant dans la
# boucle while:
#
#   res[i_j] = i_j.map { |i| wc1(fichs[i]) }
#
# Or, cela generait... parfois une erreur. Condition de course liee a
# la mise en oeuvre de l'acces par tranche de Ruby? Toujours est-il
# que le probleme semble avoir disparu avec le code de bas niveau
# ci-bas.
#


#@@@/wc_task_bag/wc/
def wc_task_bag( fichiers, taille_tache = 1 )
  res = Array.new(fichiers.size) # Tableau des resultats.

  nb_travailleurs = PRuby.nb_threads

  # On cree le sac de taches et y on met les taches:
  # une tache = un intervalle (Range) avec taille_tache
  # indices consecutifs du tableau fichiers
  # (sans depasser le dernier indice!).
  sac_taches = PRuby::TaskBag.new( nb_travailleurs )

  (0...fichiers.size).step( taille_tache ) do |i|
    j = [i + taille_tache - 1, fichiers.size - 1].min
    sac_taches.put i..j
  end

  # On active les travailleurs et on attend qu'ils terminent.
  PRuby.pcall( 0...nb_travailleurs,
               lambda do |_num_thread| # Numero pas important!
                 while i_j = sac_taches.get
                   i_j.each do |k|
                     res[k] = wc1( fichiers[k] )
                   end
                 end
               end
             )

  res
end
#@@@

#@@@/wc_task_bag_each/wc/
def wc_task_bag_each( fichiers, taille_tache = 1 )
  res = Array.new(fichiers.size) # Tableau des resultats.

  nb_travailleurs = PRuby.nb_threads

  # On cree le sac de taches et y on met les taches:
  # une tache = un intervalle (Range) avec taille_tache
  # indices consecutifs du tableau fichiers
  # (sans depasser le dernier indice!).
  sac_taches = PRuby::TaskBag.new( nb_travailleurs )

  (0...fichiers.size).step( taille_tache ) do |i|
    j = [i + taille_tache - 1, fichiers.size - 1].min
    sac_taches.put i..j
  end

  # On active les travailleurs et on attend qu'ils terminent.
  PRuby.pcall( 0...nb_travailleurs,
               lambda do |_num_thread| # Numero pas important!
                 sac_taches.each do |i_j|
                   i_j.each do |k|
                     res[k] = wc1( fichiers[k] )
                   end
                 end
               end
             )

  res
end
#@@@

#@@@/wc_task_bag_create_and_run/wc/
def wc_task_bag_create_and_run( fichiers, taille_tache = 2 )
  nb_travailleurs = PRuby.nb_threads

  # Les taches a mettre initialement dans le sac.
  taches = (0...fichiers.size)
    .step( taille_tache )
    .map { |i| i..[i + taille_tache - 1, fichiers.size - 1].min }

  res = Array.new(fichiers.size) # Tableau des resultats.

  # On active les travailleurs et on attend qu'ils terminent.
  PRuby::TaskBag.create_and_run( nb_travailleurs, *taches ) do |sac_taches|
    sac_taches.each do |i_j|
      res[i_j] = i_j.map { |k| wc1(fichiers[k]) }
    end
  end

  res
end
#@@@
