$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'qsort'

include QSort

[:qsort_seq, :qsort_par, :qsort_par2].each do |qsort|
  [10, 1000].each do |taille|
    describe "#{qsort}" do
      before do
        @a = Array.new( taille ) { (taille * rand).floor }
      end

      it "produit le bon resultat pour cas recursifs" do
        a = @a.clone
        @sort.send qsort, a, 0, a.size-1
        a.must_equal @a.sort
      end
    end
  end
end


