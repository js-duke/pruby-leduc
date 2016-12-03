require 'minitest/assertions'

# Reouverture de la classe Vector pour ajouter une methode distance.
#
class Vector

  # Distance par rapport a un autre Vector.
  #
  # @param autre
  # @return [Float]
  #
  def distance( autre )
    (self - autre).magnitude
  end
end

#
# Reouverture de la classe Minitest::Assertions pour definir une
# assertion specifique aux Vector.
#
module Minitest::Assertions

  # Verifie que deux vecteurs sont 'identiques' (au a une distance de
  # delta l'un de l'autre).
  #
  # @param [Vector] expected vecteur attendu
  # @param [Vector] actual vecteur effectivement obtenu
  # @param [Float] delta erreur maximal acceptee
  #
  # @return [void]
  #
  def assert_vector_in_delta( expected, actual, delta = 0.001, msg = "" )
    assert vector_in_delta(expected, actual, delta),
    "#{msg}: Expected #{expected.inspect} and #{actual.inspect} to be in delta #{delta}"
  end

  # Verifie que deux vecteurs sont differents.
  #
  # @param [Vector] expected vecteur attendu
  # @param [Vector] actual vecteur effectivement obtenu
  # @param [Float] delta erreur maximal acceptee
  #
  # @return [void]
  #
  def refute_same_items( expected, actual, delta = 0.001, msg = "" )
    refute same_items(expected, actual),
    "#{msg}: Expected #{expected.inspect} and #{actual.inspect} not to be in delta #{delta}"
  end

  private

  def vector_in_delta( expected, actual, delta )
    expected.distance(actual) < delta
  end
end
