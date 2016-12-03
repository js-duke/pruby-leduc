$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'jackson'

describe "probleme de Jackson" do
  before do
    @donnees  = ["abc ** dsds cssa", "ssdsx", "fssfdfdfdfdfdf", "s.s.**xtx*zy"]
    @attendus = ["abc ", "^ ds", "ds c", "ssas", "sdsx", "fssf", "dfdf", "dfdf", "dfs.", "s.^x", "tx*z", "y"]
  end

  [:traiter_flux, :traiter_flux_lambda_var, :traiter_flux_peek].each do |traiter_flux|
    it "traite le probleme de Jackson avec #{traiter_flux}" do
      r = send traiter_flux, 4, @donnees

      r[0..-2].all? { |x| x.size == 4 }.must_equal true
      r[-1].size.must_be :<=, 4
      r.must_equal @attendus
    end
  end
end
