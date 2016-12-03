$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

class Arbre
end

class Feuille < Arbre
  attr_reader :valeur

  def initialize( val )
    @valeur = val
  end

  def somme
    @valeur
  end
end

class Noeud < Arbre
  attr_reader :gauche, :droite

  def initialize( g, d )
    @gauche = g
    @droite = d
  end

  def somme
    fg = PRuby.future { gauche.somme }
    fd = droite.somme

    fg.value + fd
  end
end
