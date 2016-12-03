$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

#@@@/sommation_tableau_rec_future/sommation_tableau/
def sommation_tableau_rec( a )
  def sommation_tableau_rec_ij( a, i, j )
    return a[i] if i == j

    r1, r2 = nil, nil
    mid = (i + j) / 2

    PRuby.pcall\
    lambda { r1 = sommation_tableau_rec_ij(a, i, mid) },
    lambda { r2 = sommation_tableau_rec_ij(a, mid+1, j) }

    r1 + r2
  end

  return 0 if a.size == 0
  sommation_tableau_rec_ij( a, 0, a.size-1 )
end
#@@@

#@@@/sommation_tableau_rec_future/sommation_tableau/
def sommation_tableau_rec_future( a )
  def sommation_tableau_rec_ij_( a, i, j )
    return a[i] if i == j

    mid = (i + j) / 2

    r1 = PRuby.future { sommation_tableau_rec_ij_(a, i, mid) }
    r2 = sommation_tableau_rec_ij_(a, mid+1, j)

    r1.value + r2
  end

  return 0 if a.size == 0
  sommation_tableau_rec_ij_( a, 0, a.size-1 )
end
#@@@

#@@@/sommation_tableau_tranche/sommation_tableau/
def sommation_tableau_tranche( a )
  return 0 if a.size == 0
  return a[0] if a.size == 1

  mid = a.size / 2
  r1 = PRuby.future { sommation_tableau_tranche( a[0..mid-1] ) }
  r2 = sommation_tableau_tranche( a[mid...a.size] )
  r1.value + r2
end
#@@@

#@@@/sommation_tableau_adjacents/sommation_tableau/
def sommation_tableau_adjacents( a )
  def bornes_tranche( k, n, nb_threads )
    b_inf = k * n / nb_threads
    b_sup = (k+1) * n / nb_threads - 1
    b_inf..b_sup
  end

  def sommation_seq( a, bornes_tranche )
    bornes_tranche.reduce(0) { |somme, k| somme + a[k] }
  end

  nb_threads = PRuby.nb_threads
  DBC.require( a.size % nb_threads == 0,
               "*** Taille incorrecte: a.size = #{a.size}, \
               nb_threads = #{nb_threads}" )

  r = Array.new(nb_threads)

  PRuby.pcall (0...nb_threads),
  lambda { |k|
    r[k] = sommation_seq( a, bornes_tranche(k, a.size, nb_threads) )
  }

  r.reduce(:+)
end
#@@@

#@@@/sommation_tableau_cyclique/sommation_tableau/
def sommation_tableau_cyclique( a )
  def sommation_seq_cyclique_( a, num_thread, nb_threads )
    (num_thread...a.size).step(nb_threads).
      reduce(0) { |somme, k| somme + a[k] }
  end

  nb_threads = PRuby.nb_threads
  r = Array.new(nb_threads)

  PRuby.pcall (0...nb_threads),
  lambda { |num_thread|
    r[num_thread] = sommation_seq_cyclique_( a, num_thread, nb_threads )
  }

  r.reduce(:+)
end
#@@@

#@@@/sommation_tableau_preduce/sommation_tableau/
def sommation_tableau_preduce( a )
  a.preduce(0) { |somme, x| somme + x }
end
#@@@
