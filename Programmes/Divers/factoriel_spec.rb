$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'factoriel'

[:fact_pcall_seuil,
 :fact_future,
 :fact_un_future,
 :fact_task_bag,
 :fact_task_bag_each,
 :fact_task_bag_create_and_run,
 :fact_preduce,
 ].each do |fact|
  describe "factoriel diviser-pour-regner -- #{fact}" do
    it "execute correctement avec la recursion la plus fine" do
      n = 80
      r = send fact, n, 1
      r.must_equal (1..n).reduce(&:*)
    end

    it "execute correctement avec juste des cas de base" do
      n = 8
      r = send fact, n, 10
      r.must_equal (1..n).reduce(&:*)
    end

    it "execute correctement avec des cas recursifs" do
      n = 80
      r = send fact, n, 10
      r.must_equal (1..n).reduce(&:*)
    end

    it "execute correctement avec des tres gros cas recursifs" do
      n = 500
      r = send fact, n, 10
      r.must_equal (1..n).reduce(&:*)
    end
  end
end

[:fact_seq_lineaire,
 :fact_seq_rec,
 :fact_pcall,
] .each do |fact|
  describe "factoriel ordinaire -- #{fact}" do
    it "retourne 1 dans cas de base" do
      r = send fact, 1
      r.must_equal 1
    end

    it "retourne n! dans cas non base" do
      n = 20
      r = send fact, n
      r.must_equal (1..n).reduce(&:*)
    end

  end
end
