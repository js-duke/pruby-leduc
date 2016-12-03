$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

# Recoit une ligne et en produit les mots.
def generer_mots
  lambda do |cin, cout|
    cin.each do |ligne|
      ligne.split(" ").each { |mot| cout << mot }
    end
    cout.close
  end
end

def supprimer_commentaires
  lambda do |cin, cout|
    cin.each do |ligne|
      DBC.assert ligne != ""
      cout << ligne.split("%").first
    end
    cout.close
  end
end

# Recoit des mots et produit un tableau de mots pouvant aller sur une
# seule et meme ligne.
def paqueter_mots( largeur )
  lambda do |cin, cout|
    nb_cars = 0
    mots = []

    # Remarque: Il y a un bout de code a executer avant de fermer le
    # canal de sortie, puisqu'il faut emettre la (possible) derniere
    # serie de mots d'un ligne (possiblement) pas pleine.
    cin.each do |nouveau_mot|
      DBC.assert( nouveau_mot.size <= largeur,
                  "*** Un des mots est plus long que la largeur prevue pour les lignes" )

      if nb_cars + nouveau_mot.size + mots.size > largeur
        # La ligne serait trop longue si on ajoutait le mot, et ce en
        # tenant compte des espaces inter mots: on emet la ligne.
        cout << mots
        nb_cars = 0
        mots = []
      end
      mots << nouveau_mot
      nb_cars += nouveau_mot.size
    end
    cout << mots unless mots.empty?
    cout.close
  end
end

def ajouter_blancs( largeur )
  lambda do |cin, cout|
    cin.each do |mots|
      if mots.size == 1
        cout << mots.first
      elsif cin.peek == PRuby::EOS
        cout << mots.join(" ")
      else
        nb_blancs_a_distribuer = largeur - mots.map(&:size).reduce(&:+)
        DBC.assert nb_blancs_a_distribuer >= mots.size - 1

        min_blancs = nb_blancs_a_distribuer / (mots.size - 1)
        blancs_en_trop = nb_blancs_a_distribuer - (min_blancs * (mots.size - 1))

        res = ""
        (0...mots.size-1).each do |i|
          nb_blancs = min_blancs
          nb_blancs += 1 if i < blancs_en_trop
          res << mots[i] << " " * nb_blancs
        end
        res << mots.last

        DBC.ensure( res.size == largeur,
                    "*** Erreur distribuer_blancs: res = '#{res}' (#{res.size})" <<
                    "largeur = #{largeur}" )
        cout << res
      end
    end
    cout.close
  end
end


def justifier( largeur, donnees )
  res = []

  (PRuby.pipeline_source( donnees ) |
   supprimer_commentaires |
   generer_mots |
   paqueter_mots( largeur ) |
   ajouter_blancs( largeur ) |
   PRuby.pipeline_sink( res ) ).
    run

  res
end
