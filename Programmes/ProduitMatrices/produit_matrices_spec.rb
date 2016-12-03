$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'produit_matrices'

describe "produit de matrices a granularite fine" do
  [:produit_each,
   :produit_for,
   :produit_pcall,
   :produit_peach,
   :produit_peach_par_ligne,
   :produit_peach_par_blocs,
   :produit_peach_par_ligne_reduce,
   :produit_pmap,
   :produit_range2d].each do |produit|

    describe "#{produit}" do
      it "multiplie une petite matrice" do
        a = Matrice.new(2, 2) { |i, j| i + j }
        b = Matrice.new(2, 1) { |i, j| i + j }
        r = send produit, a, b

        r.must_equal a * b
      end

      it "multiplie une ligne fois une colonne" do
        a = Matrice.new(1, 10) { |i, j| i + j }
        b = Matrice.new(10, 1) { |i, j| i + j }
        r = send produit, a, b

        r.must_equal a * b
      end

      it "multiplie une colonne fois une ligne" do
        a = Matrice.new(100, 1) { |i, j| i + j }
        b = Matrice.new(1, 100) { |i, j| i + j }
        r = send produit, a, b

        r.must_equal a * b
      end

      it "multiplie une plus grosse matrice 10X20 * 20X10" do
        a = Matrice.new(10, 20) { |i, j| i + j }
        b = Matrice.new(20, 10) { |i, j| i + j }
        r = send produit, a, b

        r.must_equal a * b
      end
    end
  end
end
