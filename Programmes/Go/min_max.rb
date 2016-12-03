$LOAD_PATH.unshift('~/pruby/lib')

require 'pruby'

MAX_VAL = 1000

class MinMax
  def self.centralise( n )
    # Le processus maitre... qui fait <<tout le travail>>.
    maitre = lambda do |donnees, *resultats|
      val = rand(MAX_VAL)

      le_min, le_max = val, val
      (n-1).times do
        x = donnees.get
        le_min = [le_min, x].min
        le_max = [le_max, x].max
      end

      resultats.each { |canal| canal.put [le_min, le_max] }
    end

    # Les autres processus.
    travailleurs = (1...n).map do
      lambda do |donnees, resultat|
        val = rand(MAX_VAL)

        donnees.put val
        le_min, le_max = resultat.get

        fail "*** Min invalide" if le_min > val
        fail "*** Max invalide" if le_max < val
      end
    end

    # Le canal utilise par le processus maitre pour recevoir les
    # donnees des autres processus.
    donnees = PRuby::Channel.new

    # Les canaux utilises par le maitre pour retourner les resultats
    # aux autres processus.
    resultats = Array.new(n-1) { PRuby::Channel.new }

    # On active les processus.
    ( [maitre.go(donnees, *resultats)] + (0...n-1).map { |i| travailleurs[i].go(donnees, resultats[i]) } )
      .map(&:join)

    true
  end

  def self.symetrique( n )
    # Les differents processus, tous identiques, qui different
    # seulement par la liste des canaux transmis lorqu'on les cree.
    procs = (0...n).map do
      lambda do |mon_canal, *autres_canaux|
        val = rand(MAX_VAL)

        # On transmet la valeur courante a chacun des autres
        # processus.
        autres_canaux.each { |canal|  canal.put val }

        # On recoit les valeurs des autres processus et traite.
        le_min, le_max = val, val
        (n-1).times do
          autre_val = mon_canal.get
          le_min = [le_min, autre_val].min
          le_max = [le_max, autre_val].max
        end

        fail "*** Min invalide" if le_min > val
        fail "*** Max invalide" if le_max < val
      end
    end

    # Les differents canaux, tous utilises de la meme facon.
    canaux = Array.new(n) { PRuby::Channel.new }

    # On lance les processus.
    (0...n)
      .map { |i| procs[i].go(canaux[i], *canaux[0...i], *canaux[i+1..-1]) }
      .map(&:join)
    true
  end

  def self.anneau( n )
    # Les divers processus.
    procs = []

    # Le processus 0, qui initie la circulation des jetons dans
    # l'anneau.
    procs << lambda do |gauche, droite|
      val = rand(MAX_VAL)

      # Premiere passe.
      droite.put [val, val]

      # Deuxieme passe.
      le_min, le_max = gauche.get
      droite.put [le_min, le_max]

      fail "*** Min invalide" if le_min > val
      fail "*** Max invalide" if le_max < val
    end

    # Les autres processus.
    (1...n).each do |i|
      procs << lambda do |gauche, droite|
        val = rand(MAX_VAL)

        # Premiere passe.
        le_min, le_max = gauche.get
        le_min = [le_min, val].min
        le_max = [le_max, val].max
        droite.put [le_min, le_max]

        # Deuxieme passe.
        le_min, le_max = gauche.get
        droite.put [le_min, le_max] # unless i == n-1

        fail "*** Min invalide" if le_min > val
        fail "*** Max invalide" if le_max < val
      end
    end

    # On definit les differents canaux.
    canaux = Array.new(n) { PRuby::Channel.new }

    # On active les processus.
    (0...n)
      .map { |i| procs[i].go( canaux[i], canaux[i == n-1 ? 0 : i+1] ) }
      .map(&:join)
    true
  end
end
