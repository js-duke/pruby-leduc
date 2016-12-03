############################################################
#
# Ajout d'une methode a la classe Range -- donc avec "monkey patch" --
# pour permettre la creation d'une forme de Range a deux (2)
# dimensions.
#
############################################################

class Range

  # Les elements du Range qui recoit ce message sont utilises comme
  # premiers elements des paires creees a partir des elements du Range
  # other. Il s'agit donc de produire le produit cartesien, d'ou
  # l'utilisation surchargee de '*'.
  #
  # @param [Range] other Autre range a utiliser pour les autres elements des paires
  # @return [Array<Fixnum,Fixnum>] Une liste des paires provenant des deux Range (produit cartesien)
  #
  # @example
  #    (1..3)*(2..3) = [[1,2], [1,3], [2,2], [2,3], [3,2], [3,3]]
  #
  def *( other )
    DBC.check_type other, Range

    paires = []
    each do |i|
      other.each do |j|
        paires << [i, j]
      end
    end

    paires
  end
end
