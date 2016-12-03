$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'
require 'matrice'

def produit_scalaire_for( v1, v2 )
  DBC.require v1.size == v2.size
  r = 0
  for i in 0...v1.size
    r += v1[i] * v2[i]
  end

  r
end

# Calcule le produit scalaire de deux vecteurs de nombres.
#
# @param [Array<Numeric>] v1
# @param [Array<Numeric>] v2
# @require v1.size == v2.size
# @return [Numeric] Le produit scalaire de v1 et v2
#
def produit_scalaire_reduce( v1, v2 )
  DBC.require v1.size == v2.size
  (0...v1.size).reduce(0) { |somme, k| somme + v1[k] * v2[k] }
end

def produit_for( a, b )
  DBC.check_type a, Matrice
  DBC.check_type b, Matrice
  DBC.require a.nb_colonnes == b.nb_lignes

  c = Matrice.new( a.nb_lignes, b.nb_colonnes )

  for i in 0...c.nb_lignes
    for j in 0...c.nb_colonnes
      c[i, j] = produit_scalaire( a.ligne(i), b.colonne(j) )
    end
  end

  c
end

def produit_scalaire( v1, v2 )
  DBC.require v1.size == v2.size

  r = 0
  (0...v1.size).each do |i|
    r += v1[i] * v2[i]
  end

  r
end

#@@@/produit_each/produit/
def produit_each( a, b )
  DBC.require a.nb_colonnes == b.nb_lignes

  c = Matrice.new( a.nb_lignes, b.nb_colonnes )

  (0...c.nb_lignes).each do |i|
    (0...c.nb_colonnes).each do |j|
      c[i, j] = 0
      (0...a.nb_colonnes).each do |k|
        c[i, j] += a[i, k] * b[k, j]
      end
    end
  end

  c
end
#@@@

# Calcule le produit matriciel de deux matrices.
#
# @param [Matrice<Numeric>] a
# @param [Matrice<Numeric>] b
# @require a.nb_colonnes == b.nb_lignes
# @return [Matrice<Numeric>] Le produit matriciel de a et b
#
#@@@/produit_peach/produit/
def produit_peach( a, b )
  c = Matrice.new( a.nb_lignes, b.nb_colonnes )
  nbl = c.nb_lignes # Vars...pour mise en page
  nbc = c.nb_colonnes

  (0...nbl).peach(nb_threads: nbl) do |i|
    (0...nbc).peach(nb_threads: nbc) do |j|
      c[i, j] = 0
      (0...a.nb_colonnes).each do |k|
        c[i, j] += a[i, k] * b[k, j]
      end
    end
  end

  c
end
#@@@

#@@@/produit_peach_par_ligne/produit/
def produit_peach_par_ligne( a, b )
  c = Matrice.new( a.nb_lignes, b.nb_colonnes )

  (0...c.nb_lignes).peach( nb_threads: c.nb_lignes ) do |i|
    (0...c.nb_colonnes).each do |j|
      c[i, j] = 0
      (0...a.nb_colonnes).each do |k|
        c[i, j] += a[i, k] * b[k, j]
      end
    end
  end

  c
end
#@@@

#@@@/produit_peach_par_blocs/produit/
def produit_peach_par_blocs( a, b )
  c = Matrice.new( a.nb_lignes, b.nb_colonnes )

  (0...c.nb_lignes).peach do |i|
    (0...c.nb_colonnes).each do |j|
      c[i, j] = 0
      (0...a.nb_colonnes).each do |k|
        c[i, j] += a[i, k] * b[k, j]
      end
    end
  end

  c
end
#@@@

#@@@/produit_peach_par_ligne_reduce/produit/
def produit_peach_par_ligne_reduce( a, b )
  c = Matrice.new( a.nb_lignes, b.nb_colonnes )

  (0...c.nb_lignes).peach do |i|
    (0...c.nb_colonnes).each do |j|
      c[i, j] = (0...a.nb_colonnes).reduce(0) do |p, k|
        p + a[i, k] * b[k, j]
      end
    end
  end

  c
end
#@@@

#@@@/produit_pmap/produit/
def produit_pmap( a, b )
  # PAS ENCORE PMAP: Juste vars auxiliaires!

  n1 = a.nb_lignes
  n2 = a.nb_colonnes
  n3 = b.nb_colonnes

  c = Matrice.new( n1, n3 )

  (0...n1).peach do |i|
    (0...n3).each do |j|
      c[i, j] = (0...n2).reduce(0) { |p, k| p + a[i, k] * b[k, j] }
    end
  end

  c
end
#@@@

def produit_pcall( a, b )
  DBC.check_type a, Matrice
  DBC.check_type b, Matrice
  DBC.require a.nb_colonnes == b.nb_lignes

  c = Matrice.new( a.nb_lignes, b.nb_colonnes )

  PRuby.pcall\
  0...c.nb_lignes, lambda { |i|
    PRuby.pcall\
    0...c.nb_colonnes, lambda { |j|
      c[i, j] = produit_scalaire( a.ligne(i), b.colonne(j) )
    }
  }

  c
end

def produit_range2d( a, b )
  DBC.check_type a, Matrice
  DBC.check_type b, Matrice
  DBC.require a.nb_colonnes == b.nb_lignes

  c = Matrice.new( a.nb_lignes, b.nb_colonnes )

  ((0...c.nb_lignes) * (0...c.nb_colonnes)).peach do |i, j|
    c[i, j] = produit_scalaire( a.ligne(i), b.colonne(j) )
  end

  c
end
