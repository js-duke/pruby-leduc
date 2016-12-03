$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'min_max'

describe MinMax do
  it "execute la version centralise" do
    assert MinMax.centralise( 5 )
  end

  it "execute la version symetrique" do
    assert MinMax.symetrique( 5 )
  end

  it "execute la version en anneau" do
    assert MinMax.anneau( 5 )
  end
end
