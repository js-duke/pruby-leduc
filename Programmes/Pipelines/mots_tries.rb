$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

#@@@/trier_mots_uniques/trier_mots_uniques/
def trier_mots_uniques( fich_entree, fich_sortie )
  generer_mots = lambda do |cin, cout|
    cin.each do |ligne|
      ligne.split( /\s+/ ).each { |mot| cout << mot }
    end
    cout.close
  end

  filtrer_mots_invalides = lambda do |cin, cout|
    cin.each { |mot| cout << mot if /^\w+$/ =~ mot }
    cout.close
  end

  trier = lambda do |cin, cout|
    # Channel definit each et inclut Enumerable!
    cin.sort.each { |mot| cout << mot }
    cout.close
  end

  supprimer_doublons = lambda do |cin, cout|
    precedent = nil
    cin.each do |mot|
      cout << mot if mot != precedent
      precedent = mot
    end
    cout.close
  end

  (PRuby.pipeline_source(fich_entree) |
   generer_mots |
   filtrer_mots_invalides |
   trier |
   supprimer_doublons |
   PRuby.pipeline_sink(fich_sortie))
    .run
end
#@@@
