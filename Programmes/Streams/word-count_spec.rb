$LOAD_PATH.unshift('../../spec')

EXAMPLE = true #&& false

require 'spec_helper'
require_relative 'word-count'

describe "word-count" do
  before do
    @lines  = ["abc abc abc x x def def", "abc def", "x x x ", "x abc"]

    @counts = [["abc", 5], ["def", 3], ["x", 6]]

    @lines  = ["abc def ghi", "abc def", "abc"] if EXAMPLE

    @counts = [["abc", 3], ["def", 2], ["ghi", 1]] if EXAMPLE
  end

  METHODS = [:word_count_spark1,
             :word_count_spark2,
             :word_count_flink1,
             :word_count_flink2,
             :word_count_flink3,
             :word_count_flink4,
             :word_count_java8,
             :word_count_flume1,
             :word_count_GDF,
            ]

  METHODS.each do |methode|
    it "produit le bon resultat avec la methode #{methode}" do
      r = send methode, @lines
      r.sort.must_equal @counts
    end
  end
end
