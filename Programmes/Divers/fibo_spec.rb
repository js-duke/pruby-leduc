$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'fibo'

describe "fibonacci" do
  [:fibo_par, :fibo_seq].each do |fibo|
    describe "#{fibo}" do

      before do
        @fib = Fibo.new
      end

      it "produit le bon resultat pour cas simples" do
        r = @fib.send fibo, 0
        r.must_equal 0

        r = @fib.send fibo, 1
        r.must_equal 1
      end

      it "produit le bon resultat pour cas recursifs" do
        r = @fib.send fibo, 10
        r.must_equal 55
      end
    end
  end
end
