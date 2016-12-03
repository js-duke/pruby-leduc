$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'wc'

describe "wc" do
  describe "wc1 -- pour un seul fichier" do
    before do
      @fich = "wc.rb"
      @res = `wc #{@fich}`.
        strip!.
        split(/\s+/)[0..2].
        map(&:to_i) << @fich
    end

    it "donne le meme resultat que wc" do
      r = wc1 @fich
      r.must_equal @res
    end
  end

  [:wc_seq,
  :wc_pmap,
  :wc_cyclique,
  :wc_dynamique,
  :wc_task_bag,
  :wc_task_bag_each,
  :wc_task_bag_create_and_run,
  ].each do |wc|
    describe "#{wc}" do
      before do
        nb = 10
        @fichs = Array.new( nb ) { "wc.rb" }
        res1 = `wc wc.rb`.
          strip.
          split(/\s+/)[0..2].
          map(&:to_i) << "wc.rb"
        @res = Array.new( nb ) { res1 }
      end

      it "donne le meme resultat que wc" do
        r = send wc, @fichs
        r.must_equal @res
      end
    end
  end
end
