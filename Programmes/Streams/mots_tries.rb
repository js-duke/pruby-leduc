$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

#@@@/trier_mots_uniques_apply/trier_mots_uniques/
def trier_mots_uniques_apply( fich_entree, fich_sortie )
  generer_mots = lambda do |s|
    s.flat_map { |ligne| ligne.split( /\s+/ ) }
  end

  filtrer_mots_invalides = lambda do |s|
    s.filter { |mot| /^\w+$/ =~ mot }
  end

  trier = lambda do |s|
    s.sort
  end

  supprimer_doublons = lambda do |s|
    s.fastflow( stateful: true, precedent: nil ) do |precedent, mot|
      if mot != precedent
        [mot, mot]
      else
        [precedent, PRuby::GO_ON]
      end
    end
  end

  PRuby::Stream.source(fich_entree)
    .apply( generer_mots )
    .apply( filtrer_mots_invalides )
    .apply( trier )
    .apply( supprimer_doublons )
    .sink( fich_sortie )
end
#@@@

#@@@/trier_mots_uniques_apply_bis/trier_mots_uniques/
def trier_mots_uniques_apply_bis( fich_entree, fich_sortie )
  generer_mots = lambda do |s|
    s.flat_map { |ligne| ligne.split( /\s+/ ) }
  end

  filtrer_mots_invalides = lambda do |s|
    s.filter { |mot| /^\w+$/ =~ mot }
  end

  trier = lambda do |s|
    s.sort
  end

  supprimer_doublons = lambda do |s|
    s.fastflow( stateful: true, precedent: nil ) do |precedent, mot|
      if mot != precedent
        [mot, mot]
      else
        [precedent, PRuby::GO_ON]
      end
    end
  end

  (PRuby::Stream.source(fich_entree) >>
   generer_mots >>
   filtrer_mots_invalides >>
   trier >>
   supprimer_doublons)
    .sink( fich_sortie )
end
#@@@

#@@@/trier_mots_uniques/trier_mots_uniques/
def trier_mots_uniques( fich_entree, fich_sortie )
  PRuby::Stream.source(fich_entree)
    .flat_map { |ligne| ligne.split( /\s+/ ) }
    .filter { |mot| /^\w+$/ =~ mot }
    .sort
    .uniq
    .sink( fich_sortie )
end
#@@@
