require_relative 'spec_helper'
require 'dbc'

describe DBC do

  describe "#check_type" do
    it "accepts and checks a simple type" do
      lambda { DBC.check_type 10, Fixnum }.must_be_silent
      lambda { DBC.check_type 10, String }.must_raise DBC::Failure
    end

    it "accpets and checks a set of types" do
      lambda { DBC.check_type 10, [Fixnum, String] }.must_be_silent
      lambda { DBC.check_type 10, [String] }.must_raise DBC::Failure
      lambda { DBC.check_type 10, [] }.must_raise DBC::Failure
    end
  end

  describe "#check_value" do
    it "accepts and checks a simple value" do
      lambda { DBC.check_value 10, 10 }.must_be_silent
      lambda { DBC.check_value "bac", "bac" }.must_be_silent
      lambda { DBC.check_value :FOO, :FOO }.must_be_silent

      lambda { DBC.check_value 100, 10 }.must_raise DBC::Failure
      lambda { DBC.check_value "ac", "bac" }.must_raise DBC::Failure
      lambda { DBC.check_value 10, :FOO }.must_raise DBC::Failure
    end

    it "accepts and checks a set of values" do
      lambda { DBC.check_value 10, [20, 10, 30, PRuby::EOS] }.must_be_silent
      lambda { DBC.check_value :FOO, [:FOO, 10, 30, PRuby::EOS] }.must_be_silent
      lambda { DBC.check_value 10, [String] }.must_raise DBC::Failure
      lambda { DBC.check_value 10, [] }.must_raise DBC::Failure
    end
  end

end
