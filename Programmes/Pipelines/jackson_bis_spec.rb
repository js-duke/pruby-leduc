$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'jackson_bis'

describe "probleme de Jackson" do
  before do
    @donnees  = ["abc ** dsds cssa", "ssdsx", "fssfdfdfdfdfdf", "s.s.**xtx*zy"]
    @attendus = ["abc ", "^ ds", "ds c", "ssas", "sdsx", "fssf", "dfdf", "dfdf", "dfs.", "s.^x", "tx*z", "y"]
  end

  it "traite le probleme de Jackson avec jackson2" do
    res = Array.new
    jackson @donnees, res, 4

    res[0..-2].all? { |x| x.size == 4 }.must_equal true
    res[-1].size.must_be :<=, 4
    res.must_equal @attendus
  end
end
