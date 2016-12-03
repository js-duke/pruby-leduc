$LOAD_PATH.unshift('.', 'lib')

require 'dbc'
require 'pruby'

############################################################
#
# Classe pour des matrices a deux dimensions (objets mutables).
#
# Il existe deja une classe Matrix dans les gems publics, mais il
# s'agit d'une classe pour des matrices immuables. Il y a donc
# uniquement des constructeurs monolitique, c'est-a-dire qu'il est
# impossible de modifier une cellule d'une matrice une fois qu'elle a
# ete creee (style purement fonctionnel seulement, donc).
#
# @note Dans ce qui suit, dans les clauses ensure, des expressions
#       telles que ".get(i)" et ".get(i, j)" sont parfois
#       utilisees. Elles sont equivalentes a "[i]" ou "[i, j]". Cette
#       notation a ete utilisee parce que yard creait des problemes de
#       reference en utisant directement les crochets.
#
############################################################

class Matrice

  class << self
    # Pour indiquer si on doit, ou non, effectuer les verifications des bornes lors des acces aux elements de la matrice.
    #
    # Valeur par defaut = nil. Donc, par defaut, on fait les
    # verifications des bornes.  Par contre, on peut vouloir ne pas
    # les faire, notamment, pour mesurer/comparer les temps
    # d'execution et l'acceleration absolue.
    #
    # @return [Bool]
    #
    attr_accessor :no_bound_check
  end

  # @return [Fixnum]
  attr_reader :nb_lignes

  # @return [Fixnum]
  attr_reader :nb_colonnes

  # Creation d'une matrice.
  #
  # @param nb_lignes [Fixnum] Nombre de lignes
  # @param nb_colonnes [Fixnum] Nombre de colonnes
  # @param elems [Array<Array>] Les divers elements de la matrice
  # @param rapide [Bool] Si on veut une mise en oeuvre plus rapide mais
  #        avec certaines operations en moins
  # @require elems => elems.size == nb_lignes && elems.get(i).size == nb_colonnes
  #
  def initialize( nb_lignes, nb_colonnes = nil, elems = nil, rapide = nil )
    # Par defaut: Meme nombre de colonnes que de lignes.
    # Supprime de l'entete car yard signalait une erreur et terminait.
    nb_colonnes ||= nb_lignes

    DBC.require nb_lignes > 0 && nb_colonnes > 0, "*** Les nombres de lignes et de colonnes doivent etre positifs"
    @nb_lignes, @nb_colonnes = nb_lignes, nb_colonnes

    if elems
      DBC.require elems.size == nb_lignes, "*** Le nombre d'elements fournis pour initialize doit etre egal a nb_lignes"
      DBC.require elems.all? { |ligne| ligne.size == nb_colonnes }, "*** Les lignes doivent avoir nb_colonnes (#{nb_colonnes}) elements"
      DBC.require !block_given?, "*** Un bloc ne peut pas etre fourni si des elements sont specifies"
    end

    @rapide = !!rapide
    if @rapide
      @elems = Array.new( nb_lignes * nb_colonnes )

      class << self
        def [](i, j); @elems[i * @nb_colonnes + j]; end
        def []=(i, j, x); @elems[i * @nb_colonnes + j] = x; end
        def ligne( _i ); DBC.assert false, "*** ligne pas definie"; end
        def colonne( _i ); DBC.assert false, "*** colonne pas definie"; end
      end
    else
      @elems = Array.new( nb_lignes )
      @elems.map! { Array.new(nb_colonnes) }
    end

    if block_given? || elems
      (0...nb_lignes).each do |i|
        (0...nb_colonnes).each do |j|
          self[i, j] = elems ? elems[i][j] : yield(i, j)
        end
      end
    end
  end

  # Retourne la ieme ligne de la matrice.
  #
  # @param [Fixnum] i L'indice de la ligne desiree
  # @return [Array] La ieme ligne
  # @require 0 <= i < nb_lignes
  #
  def ligne( i )
    check_bounds i, nb_lignes unless Matrice.no_bound_check

    @elems[i]
  end

  # Retourne la jeme colonne de la matrice.
  #
  # @param [Fixnum] j L'indice de la colonne desiree
  # @return [Array] La jeme colonne
  # @require 0 <= j < nb_colonnes
  #
  def colonne( j )
    check_bounds j, nb_colonnes unless Matrice.no_bound_check

    (0...nb_lignes).map { |i| @elems[i][j] }
  end

  # Retourne un element ou une "tranche" d'elements de la matrice.
  #
  # @param [Fixnum, Range] i L'index ou l'intervalle d'index desire
  # @param [Fixnum, Range] j L'index ou l'intervalle d'index desire
  # @require Que les bornes soient valides
  # @return SI i & j sont des Fixnum ALORS self.get(i, j) SINON la tranche indiquee
  #
  def []( i, j )
    if i.class == Fixnum && j.class == Fixnum
      # Un seul element!
      unless Matrice.no_bound_check
        check_bounds i, nb_lignes
        check_bounds j, nb_colonnes
      end
      return @elems[i][j]
    end

    is = define_range( i, nb_lignes )
    js = define_range( j, nb_colonnes )

    lignes = Array.new(is.last - is.first + 1)
    lignes.each_index do |i|
      lignes[i] = Array.new(js.last - js.first + 1)
    end
    lignes.each_index do |i|
      lignes[i].each_index do |j|
        lignes[i][j] = self[i + is.first, j + js.first]
      end
    end

    if i.class == Fixnum || j.class == Fixnum
      lignes.first
    else
      lignes
    end
  end

  # Modifie l'element a la position i, j
  #
  # @param i [Fixnum] No. de ligne
  # @param j [Fixnum] No. de colonne
  # @param x La nouvelle valeur
  # @require 0 <= i < nb_lignes && 0 <= j < nb_colonnes
  # @ensure self.get(i, j) == x
  # @return x
  #
  def []=( i, j, x )
    check_bounds i, nb_lignes unless Matrice.no_bound_check
    check_bounds j, nb_colonnes unless Matrice.no_bound_check

    @elems[i][j] = x
  end

  # Transforme les elements de la matrice en un Array d'Array
  #
  # @return [Array<Array>]
  #
  def to_a
    @elems
  end

  # Produit matriciel iteratif et sequentiel.
  #
  # @param autre [Matrice]
  # @require nb_colonnes == autre.nb_lignes
  # @return [Matrice]
  #
  def *( autre )
    DBC.require nb_colonnes == autre.nb_lignes, '*** Le nombre de lignes de la 2e matrice doit etre = nombre de colonne de la 1ere'

    r = Matrice.new( nb_lignes, autre.nb_colonnes, nil, @rapide )
    (0...nb_lignes).each do |i|
      (0...autre.nb_colonnes).each do |j|
        r[i, j] = 0
        (0...nb_colonnes).each do |k|
          r[i, j] += self[i,k] * autre[k,j]
        end
      end
    end

    r
  end

  # Comparaison d'egalite.
  #
  # @param autre [Matrice]
  # @return [Bool]
  #
  def ==( autre )
    return false if nb_lignes != autre.nb_lignes
    return false if nb_colonnes != autre.nb_colonnes
    (0...nb_lignes).each do |i|
      (0...nb_colonnes).each do |j|
        return false if self[i, j] != autre[i, j]
      end
    end

    true
  end

  # Representation de la matrice en une chaine de caracteres.
  #
  # @return [String]
  #
  def to_s
    s = ''
    (0...nb_lignes).each do |i|
      (0...nb_colonnes).each do |j|
        x = self[i, j]
        s << (x ? "#{x} " : '? ')
      end
      s << "\n"
    end

    s
  end


  # Iterateur sequentiel sur les differents index/element de la matrice.
  #
  # @yieldparam [Fixnum] i
  # @yieldparam [Fixnum] j
  # @yieldparam [Fixnum] item self[i, j]
  # @yieldreturn [void]
  #
  def each_index
    nb_lignes.times do |i|
      nb_colonnes.times do |j|
        yield(i, j, self[i, j])
      end
    end
  end

  def peach_index_ligne( opts = {}, &block )
    DBC.require !@rapide, '*** Operation impossible si mise en oeuvre rapide'
    @elems.peach_index( opts, &block )
  end

  private

  def check_bounds( i, nb )
    DBC.require 0 <= i && i < nb, '*** i < 0 || i > nb'
  end

  def define_range( k, nb )
    if k == :*
      ks = 0..nb-1
    elsif k.class == Fixnum
      ks = k..k
    else
      DBC.require k.class == Range, "*** La classe de l'argument k doit etre Range (et non #{k.class})"
      ks = k
    end
    unless Matrice.no_bound_check
      check_bounds ks.first, nb
      check_bounds ks.last, nb
    end

    ks
  end
end

class Array
  # Conversion d'un Array en une matrice
  #
  # @return [Matrice]
  #
  def to_matrice
    if size > 0
      if self[0].class == Array
        Matrice.new( size, self[0].size, self )
      else
        Matrice.new( 1, size, [self])
      end
    end
  end

end
