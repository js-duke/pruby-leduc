############################################################
#
# Quelques methodes utiles pour le debogage.
#
# Remarque: pour utiliser ce module, il faut tout d'abord charger
# le fichier:
#    require 'dump'
#
# Ensuite, on effectue des appels de la forme suivante:
#   Dump.dump( :symbol, binding[, chainePourContexte] )
#   Dump.inspect( :symbol, binding[, chainePourContexte] )
#
############################################################

module Dump
  $dump = true

  module_function

  # Affiche la valeur associee a un symbole dans un
  # environnement. Utile pour deboger facilement au lieu de puts.
  #
  # N'a aucun effet si $dump est faux (false ou nil).
  #
  # @param [Symbol] sym Symbole de la variable qu'on veut afficher
  # @param [Binding] bndg Contexte duquel provient la variable
  # @param [nil,!nil] cl Indique si on veut aussi afficher le contexte des appelants
  # @return [void]
  #
  # @example On veut afficher la valeur de la variable foo
  #    foo = 3
  #    Dump.foo :foo, binding # => At ... : foo = 3
  #
  def dump( sym, bndg, cl = nil )
    return unless $dump

    v = eval( sym.id2name, bndg )
    if v.nil?
      puts "At #{Dump.contexte cl}::#{Dump.separateur cl}#{sym.id2name} = nil"
    else
      puts "At #{Dump.contexte cl}::#{Dump.separateur cl}#{sym.id2name} = '#{v}'"
    end
  end

  # Semblable a dump, mais utilise inspect au lieu de puts.
  #
  # @param (see .dump)
  # @return (see .dump)
  #
  def inspect( sym, bndg, cl = nil )
    return unless $dump

    puts "At #{Dump.contexte cl}::#{Dump.separateur cl}#{sym.id2name} = #{(eval sym.id2name, bndg).inspect}"
  end

  private

  def contexte( cl )
    cl.nil? ? caller : cl
  end

  def separateur( cl )
    cl.nil? ? "\n\t" : ' '
  end
end
