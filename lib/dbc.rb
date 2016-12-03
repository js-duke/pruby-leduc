############################################################
# Support pour l'approche DBC... tres informel et "light"!
#
# @note DBC = Design By Contract, approche proposee initialement par Bertrand Meyer,
#   notamment dans le langage Eiffel.
#
############################################################

module DBC

  class Failure < RuntimeError; end

  module_function

  # Verifie une assertion generale.
  #
  # @param [Bool] condition La condition a verifier
  # @param [String] message Le message a afficher si la condition n'est pas verifiee
  # @return [void] Aucun resultat
  # @raise DBC::Failure si la condition est fausse, aucun effet sinon
  #
  def assert( condition, message = nil )
    fail Failure, "Assertion failed: #{message}" unless condition
  end

  # Verifie une precondition (antecedent).
  #
  # @param (see #assert)
  # @return (see #assert)
  # @raise (see #assert)
  #
  def require( condition, message = nil )
    fail Failure, "Precondition failed: #{message}" unless condition
  end

  # Verifie une postcondition (consequent).
  #
  # @param (see #assert)
  # @return (see #assert)
  # @raise (see #assert)
  #
  def ensure( condition, message = nil )
    fail Failure, "Postcondition failed: #{message}" unless condition
  end

  # Verifie un invariant.
  #
  # @param (see #assert)
  # @return (see #assert)
  # @raise (see #assert)
  #
  def invariant( condition, message = nil )
    fail Failure, "Invariant failed: #{message}" unless condition
  end

  # Verifie le type d'un argument d'une methode. Utile pour avoir des constructeurs flexibles.
  #
  # @param val La valeur dont on veut verifier le type
  # @param [Class, Array<Class>]  expected_type Les types permis/attendus
  # @param [String] message Le message a afficher si l'argument n'est pas d'un type approprie
  # @return (see #assert)
  # @raise DBC::Failure si la valeur n'est pas du ou des types indiques, aucun effet sinon
  #
  def check_type( val, expected_type, message = '*** ' )
    if expected_type.class == Array
      fail Failure, message + "The type of #{val} is not in #{expected_type.inspect}" unless expected_type.include? val.class
    else
      fail Failure, message + "The type of #{val} is not #{expected_type.inspect}" unless val.kind_of? expected_type
    end
  end

  # Verifie la valeur specifique d'un argument d'une methode. Utile pour avoir des constructeurs flexibles.
  #
  # @param val La valeur dont on veut verifier si elle est aceptable
  # @param expected_value [#==, Array<#==>] Les valeurs permises/attendues
  # @param message Le message a afficher si l'argument n'a pas une valeur appropriee
  # @return (see #assert)
  # @raise DBC::Failure si la valeur n'est pas permise, aucun effet sinon
  #
  def check_value( val, expected_value, message = '*** ' )
    if expected_value.class == Array
      fail Failure, message + "Value #{val} is not in #{expected_value.inspect}" unless expected_value.include? val
    else
      fail Failure, message + "Value #{val} is not equal to #{expected_value.inspect}" unless val == expected_value
    end
  end

  # Verifie si les arguments specifies par mot-cles contiennent uniquement certains mots-cles permis.
  #
  # @param [Hash<Symbol,Object>] args Les differents arguments dont on veut verifier les mots-cles
  # @param [Array<Symbol>] expected_keywords Les mots-cles permis/attendus
  # @param [String] message Le message a afficher si l'argument est un mot-cle non permis
  # @return (see #assert)
  # @raise DBC::Failure si un mot-cle inapproprie est present, aucun effet sinon
  #
  def check_keyword_arguments( args, expected_keywords, message = '*** ' )
    invalid_kw = args.keys.select { |kw| !(expected_keywords.include? kw) }

    fail Failure, message + "A keyword argument (in #{invalid_kw}) is not appropriate (not in #{expected_keywords})" unless invalid_kw.empty?
  end
end
