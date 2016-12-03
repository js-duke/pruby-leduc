$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'distance_edition'

describe "calcul de la distance d'edition" do
  [:distance_rec, :distance_seq, :distance_peach].each do |distance|
    describe "#{distance}" do
      context "chaines identiques" do
        it "retourne un cout nul" do
          ch = "abcdef"
          (send distance, ch, ch ).must_equal 0
        end
      end

      context "petits chaines presque pareilles" do
        it "retourne un cout d'une simple substitution" do
          ch1 = "ad"
          ch2 = "axe"
          (send distance, ch1, ch2 ).must_equal 2
        end
      end

      context "exemple pour note de cours" do
        it "retourne un cout d'une simple substitution" do
          ch1 = "surgery"
          ch2 = "survey"
          (send distance, ch1, ch2 ).must_equal 2
        end
      end

      context "chaines presque pareilles" do
        it "retourne un cout d'une simple substitution" do
          ch1 = "abcdef"
          ch2 = "abcxef"
          (send distance, ch1, ch2 ).must_equal 1
        end
      end

      context "chaines tres differentes pareilles" do
        it "retourne le cout des suppressions" do
          ch1 = "abcdef"
          ch2 = "abxdxxexxf"
          (send distance,  ch1, ch2 ).must_equal 5
        end

        it "retourne le cout des substitutions suppressions" do
          ch1 = "abcdef"
          ch2 = "abxdxxWxxG"
          (send distance, ch1, ch2 ).must_equal 7
        end
      end
    end
  end
end
