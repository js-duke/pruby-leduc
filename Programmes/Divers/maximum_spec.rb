$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'maximum'

include Maximum

[:maximum, :maximum_, :maximum__, :maximum_log, :maximum_preduce, :maximum_t].each do |maximum|
  describe "maximum" do
    let(:nb) { 128 }
    let(:s) { r = (0...nb).map { |i| rand(nb) }; r[rand(nb)] = 9999; r }

    it "execute correctement" do
      #puts "s = #{s}, maximum = #{maximum}"
      if [:maximum__, :maximum_log, :maximum_preduce, :maximum_t].include? maximum
        $nb_threads = PRuby.nb_threads
        r = send maximum, s
      else
        r = send maximum, s, 0, nb-1
      end
      r.must_equal 9999
    end
  end
end
