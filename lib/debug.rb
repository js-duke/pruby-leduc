############################################################
# Quelques methodes utiles pour le deboggage.
############################################################

#$debug = true

$jiggle = true

class Object
  # (see Debug.__debug__)
  def _debug_( msg, dbg_level = 0 )
    Debug::__debug__ msg, dbg_level
  end

  # Permet "d'endormir" temporairement, pour une petite duree aleatoire, un Thread
  #
  # Utile pour les programmes concurrents qui pourraient avoir des
  # conditions de course, et donc pour lesquels on tente de faire
  # varier les temps d'execution des threads pour rendre visible ces
  # conditions de course.
  # @return [void]
  #
  def jiggle
    sleep rand / 10.0 if $jiggle
  end
end


############################################################
# Quelques methodes utiles pour le deboggage.
############################################################

module Debug

  # Determine si le debogage a ete active.
  #
  # @return true si le debogage a ete active, false sinon
  #
  def debug?
    $debug
  end

  # Affiche un message de debogage.
  #
  # @param [String] msg Le message a afficher
  # @param [Fixnum] dbg_level Niveau de debogage a partir duquel il faut afficher le message
  # @return [void]
  #
  def self.__debug__( msg, dbg_level = 0 )
    puts msg if dbg_level > 0 && $debug
  end

  # (see Debug.__debug__)
  def __debug__( msg, dbg_level = 0 )
    puts msg if dbg_level > 0 && $debug
  end

  alias :debug :__debug__

  alias :_debug_ :__debug__

end
