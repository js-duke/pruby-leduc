$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'eval_polynomes'

describe "probleme des polynome" do

  it "assure que eval_polynome est ok" do
    eval_polynome( 0,  [1, 2, 3]).must_equal 1
    eval_polynome( 10, [1, 2, 3]).must_equal 321
    eval_polynome( 2, [1, 2, 3, 0, 5]).must_equal 97
  end

  [:eval_polynomes,
   :eval_polynomes_pmap,
   :eval_polynomes_future,
   :eval_polynomes_pcall].each do |eval_polynomes|

    describe "#{eval_polynomes}" do
      it "produit les resultats corrects pour un petit polynome" do
        xs = [0, 1, 2, 4, 10]
        coeffs = [3, 1, 2, 0, 4]

        results = send eval_polynomes, xs, coeffs
        results.must_equal xs.map{ |x| eval_polynome(x, coeffs) }
      end

      it "produit les resultats avec un gros polynomes" do
        xs = (1..100).to_a
        coeffs = (1..100).map{ |x| x * x }
        results = send eval_polynomes, xs, coeffs
        results.must_equal xs.map{ |x| eval_polynome(x, coeffs) }
      end

      it "produit beaucoup de resultats avec un gros polynomes" do
        xs = (1..1000).to_a
        coeffs = (1..100).map{ |x| x ** x }
        results = send eval_polynomes, xs, coeffs
        results.must_equal xs.map{ |x| eval_polynome(x, coeffs) }
      end
    end
  end
end
