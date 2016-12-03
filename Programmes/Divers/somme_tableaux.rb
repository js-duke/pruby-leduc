$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

# NOTE: Les versions "X_bis" sont necessaires pour la section Sommaire
# de patrons-programmation.tex.  Autrement, on a des avertissements de
# "multiply defined labels" :(

#@@@/somme_tableaux_seq/somme_tableaux/
def somme_tableaux_seq( a, b )
  DBC.require a.size == b.size # Precondition: omise ailleurs.

  c = Array.new(a.size)

  (0...c.size).each do |k|
    c[k] = a[k] + b[k]
  end

  c
end
#@@@

#@@@/somme_tableaux_pcall_fin0/somme_tableaux/
def somme_tableaux_pcall_fin0( a, b )
  c = Array.new(a.size)

  PRuby.pcall( 0...c.size,
               lambda { |k| c[k] = a[k] + b[k] }
               )

  c
end
#@@@

#@@@/somme_tableaux_pcall_fin0_bis/somme_tableaux/
def somme_tableaux_pcall_fin0_bis( a, b )
  c = Array.new(a.size)

  PRuby.pcall( 0...c.size,
               ->( k ) { c[k] = a[k] + b[k] }
               )

  c
end
#@@@

#@@@/somme_tableaux_pcall_fin1/somme_tableaux/
def somme_tableaux_pcall_fin1( a, b, _nb_threads = nil )
  c = Array.new(a.size)

  PRuby.pcall( 0...c.size,
               lambda { |k| c[k] = a[k] + b[k] }
               )

  c
end
#@@@

#@@@/somme_tableaux_pcall_statique/somme_tableaux/
def somme_tableaux_pcall_statique( a, b, nb_threads = PRuby.nb_threads )
  DBC.require a.size == b.size && a.size % nb_threads == 0

  # Les indices pour la tranche du thread no. k.
  def indices_tranche( k, n, nb_threads )
    (k * n / nb_threads)..((k + 1) * n / nb_threads - 1)
  end

  # Somme sequentielle de la tranche pour indices (inclusif)
  def somme_seq( a, b, c, indices )
    indices.each { |k| c[k] = a[k] + b[k] }
  end

  # On alloue le tableau pour le resultat.
  c = Array.new(a.size)

  # On active les divers threads,
  # en specifiant les indices de la tranche a traiter.
  PRuby.pcall( 0...nb_threads,
               lambda do |k|
                inds = indices_tranche(k, c.size, nb_threads)
                somme_seq( a, b, c, inds )
               end
               )

  # On retourne le resultat.
  c
end
#@@@

#@@@/somme_tableaux_pcall_statique_bis/somme_tableaux/
# Les indices pour la tranche du thread no. k.
def indices_tranche( k, n, nb_threads )
  (k * n / nb_threads)..((k + 1) * n / nb_threads - 1)
end

# Somme sequentielle de la tranche pour indices (inclusif)
def somme_seq( a, b, c, indices )
  indices.each { |k| c[k] = a[k] + b[k] }
end

def somme_tableaux_pcall_statique_bis( a, b, nb_threads = PRuby.nb_threads )
  c = Array.new(a.size)

  PRuby.pcall( 0...nb_threads,
               lambda do |k|
                 somme_seq(
                   a, b, c,
                   indices_tranche(k, c.size, nb_threads)
                 )
               end
               )

  c
end
#@@@

#@@@/somme_tableaux_peach_fin/somme_tableaux/
def somme_tableaux_peach_fin( a, b, _nb_threads )
  c = Array.new(a.size)

  (0...c.size).peach( nb_threads: c.size ) do |k|
    c[k] = a[k] + b[k]
  end

  c
end
#@@@

#@@@/somme_tableaux_peach_statique/somme_tableaux/
def somme_tableaux_peach_statique( a, b, nb_threads = PRuby.nb_threads )
  c = Array.new(a.size)

  (0...c.size).peach( nb_threads: nb_threads ) do |k|
    c[k] = a[k] + b[k]
  end

  c
end
#@@@

#@@@/somme_tableaux_peach_statique_bis/somme_tableaux/
def somme_tableaux_peach_statique_bis( a, b, nb_threads = PRuby.nb_threads )
  c = Array.new(a.size)

  (0...c.size).peach( nb_threads: nb_threads ) do |k|
    c[k] = a[k] + b[k]
  end

  c
end
#@@@

#@@@/somme_tableaux_pmap/somme_tableaux/
def somme_tableaux_pmap( a, b, nb_threads = PRuby.nb_threads )
  (0...a.size).pmap( nb_threads: nb_threads ) do |k|
    a[k] + b[k]
  end
end
#@@@

#@@@/somme_tableaux_pmap_bis/somme_tableaux/
def somme_tableaux_pmap_bis( a, b, nb_threads = PRuby.nb_threads )
  (0...a.size).pmap( nb_threads: nb_threads ) do |k|
    a[k] + b[k]
  end
end
#@@@

#@@@/somme_tableaux_pcall_cyclique/somme_tableaux/
def somme_seq_cyclique( a, b, c, num_thread, nb_threads )
  (num_thread...a.size).step(nb_threads).each do |k|
    c[k] = a[k] + b[k]
  end
end

def somme_tableaux_pcall_cyclique( a, b, nb_threads = PRuby.nb_threads )
  c = Array.new( a.size )

  PRuby.pcall( 0...nb_threads,
               lambda do |num_thread|
                 somme_seq_cyclique(
                   a, b, c,
                   num_thread, nb_threads
                 )
               end
               )

  c
end
#@@@

#@@@/somme_tableaux_pmap_dynamique/somme_tableaux/
def somme_tableaux_pmap_dynamique( a, b, nb_threads = PRuby.nb_threads )
  (0...a.size).pmap( nb_threads: nb_threads, dynamic: true ) do |k|
    a[k] + b[k]
  end
end
#@@@
