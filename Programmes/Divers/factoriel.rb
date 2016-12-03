$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

#@@@/fact_seq_lineaire/fact/
def fact_seq_lineaire( n )
  if n == 0
    1
  else
    n * fact_seq_lineaire( n - 1 )
  end
end
#@@@

#@@@/fact_seq_rec/fact/
def fact_seq_rec( n )

  # Fonction auxiliaire interne:
  #   fact(n) = fact_(1, n).
  def fact_( i, j )
    if i == j
      i
    else
      mid = (i + j) / 2
      r1 = fact_( i, mid )
      r2 = fact_( mid + 1, j )

      r1 * r2
    end
  end

  fact_( 1, n )
end
#@@@

#@@@/fact_pcall/fact/
def fact_pcall( n )
  def fact_( i, j )
    # Cas de base = probleme trivial (1 seul element).
    return i if i == j

    # Cas recursif pour probleme plus complexe:
    #   solution parallele et recursive
    r1, r2 = nil, nil
    mid = (i + j) / 2

    PRuby.pcall( lambda { r1 = fact_(i, mid) },
                 lambda { r2 = fact_(mid + 1, j) } )

    r1 * r2
  end

  fact_( 1, n )
end
#@@@

#@@@/fact_pcall_seuil/fact/
def fact_pcall_seuil( n, seuil )
  def fact_( i, j, seuil )
    # Probleme simple, mais non trivial
    #   => solution iterative sequentielle.
    return (i..j).reduce(:*) if j - i <= seuil

    # Probleme complexe =>
    #   solution recursive parallele.
    r1, r2 = nil, nil
    mid = (i + j) / 2

    PRuby.pcall( lambda { r1 = fact_(i, mid, seuil) },
                 lambda { r2 = fact_(mid + 1, j, seuil) } )

    r1 * r2
  end

  fact_( 1, n, seuil )
end
#@@@

#@@@/fact_future/fact/
def fact_future( n, seuil )
  def fact_( i, j, seuil )
    # Probleme simple.
    return (i..j).reduce(:*) if j - i <= seuil

    # Probleme complexe.
    mid = (i + j) / 2
    r1 = PRuby.future { fact_(i, mid, seuil) }
    r2 = PRuby.future { fact_(mid + 1, j, seuil) }

    r1.value * r2.value
  end

  fact_( 1, n, seuil )
end
#@@@

#@@@/fact_un_future/fact/
def fact_un_future( n, seuil )
  def fact_( i, j, seuil )
    # Probleme simple.
    return (i..j).reduce(:*) if j - i <= seuil

    # Probleme complexe.
    mid = (i + j) / 2
    r1 = PRuby.future { fact_(i, mid, seuil) }
    r2 = fact_(mid + 1, j, seuil)

    r1.value * r2
  end

  fact_( 1, n, seuil )
end
#@@@

def fact_chan( n, _seuil, k = 4 )
  nb_threads = PRuby.nb_threads

  ch_in = PRuby::Channel.new
  ch_out = PRuby::Channel.new

  nb_threads.times do
    PRuby.future do
      while (v = ch_in.get) != EOS
        v1, v2 = v
        ch_out.put (v1..v1+v2-1).reduce(1) { |r, j| r * j }
      end
    end
  end

  DBC.assert n % k == 0, "*** n = #{n} doit etre divisible par k = #{k}"
  (n/k).times do |j|
    ch_in.put [j * k + 1, k]
  end

  nb_threads.times do
    ch_in.put EOS
  end

  r = 1
  (n / k).times do
    r *= ch_out.get
  end

  r
end

# Remarque: Avec plusieurs threads (plus que le nombre effectifs de
# processeurs), cette methode fonctionne correctement uniquement si
# on indique :THREAD comme sorte_de_thread pour PRuby.future!!
#@@@/fact_task_bag/mystere/
def fact_task_bag( n, seuil )

  def travailleur( sac_taches, seuil )
    res = 1
    tache = sac_taches.get
    while tache
      i, j = tache
      if j - i + 1 <= seuil
        res *= (i..j).reduce(1, :*)
        tache = sac_taches.get
      else
        m = (i + j) / 2
        tache = [i, m]
        sac_taches.put [m + 1, j]
      end
    end

    res
  end

  # On cree le sac avec la tache du probleme global.
  nb_travailleurs = PRuby.nb_threads
  sac_taches = PRuby::TaskBag.new( nb_travailleurs )
  sac_taches.put [1, n]

  # On active les travailleurs.
  ps = (0...nb_travailleurs).map do
    PRuby.future { travailleur(sac_taches, seuil) }
  end

  # On recoit les resultats et on les combine.
  ps.reduce(1) { |prod, fut| prod * fut.value }
end
#@@@

#@@@/fact_task_bag_each/mystere/
def fact_task_bag_each( n, seuil )

  def travailleur( sac_taches, seuil )
    res = 1

    sac_taches.each do |i, j|
      while j - i + 1 > seuil
        m = (i + j) / 2
        sac_taches.put [m + 1, j]
        j = m
      end
      res *= (i..j).reduce(1, :*)
    end

    res
  end

  # On cree le sac avec la tache du probleme global.
  nb_travailleurs = PRuby.nb_threads
  sac_taches = PRuby::TaskBag.new( nb_travailleurs )
  sac_taches.put [1, n]

  # On active les travailleurs.
  ps = (0...nb_travailleurs).map do
    PRuby.future { travailleur(sac_taches, seuil) }
  end

  # On recoit les resultats et on les combine.
  ps.reduce(1) { |prod, fut| prod * fut.value }
end
#@@@

#@@@/fact_task_bag_create_and_run/mystere/
def fact_task_bag_create_and_run( n, seuil )
  resultats = PRuby::TaskBag.create_and_run( PRuby.nb_threads, 1..n ) do |sac_taches|
    res = 1

    sac_taches.each do |range|
      i, j = range.begin, range.end
      while j - i + 1 > seuil
        m = (i + j) / 2
        sac_taches.put (m + 1)..j
        j = m
      end
      res *= (i..j).reduce(1, :*)
    end

    res
  end

  resultats.reduce(1, :*)
end
#@@@

#@@@/fact_preduce/fact/
def fact_preduce( n, nbt )
  (1..n).preduce( 1, nb_threads: nbt ) do |prod, k|
    prod * k
  end
end
#@@@
