require_relative 'spec_helper'
require 'pruby'

describe PRuby do
  describe "pipeline avec pipeline" do
    N = 100

    it "permet d'avoir des pipelines dans des pipelines" do
      p1 = lambda do |cin, cout|
        cin.each { |v| cout << v+1 }
        cout.close
      end


      r = []
      pipe = PRuby.pipeline_source(1..N) | (p1 | p1 | p1) | PRuby.pipeline_sink(r)
      pipe.run
      r.must_equal (1..N).map{ |k| k + 3 }

      r = []
      pipe = PRuby.pipeline_source(1..N) | (p1 | p1 | p1) | (p1 | p1) | PRuby.pipeline_sink(r)
      pipe.run
      r.must_equal (1..N).map{ |k| k + 5 }

      r = []
      pipe = PRuby.pipeline_source(1..N) | (p1 | (p1 | p1) | p1) | p1 | PRuby.pipeline_sink(r)
      pipe.run
      r.must_equal (1..N).map{ |k| k + 5 }
    end

    it "fonctionne avec NO_WAIT" do
      p1 = lambda do |cin, cout|
        cin.each do |v|
          cout << v+1
          sleep rand/100
        end
        cout.close
      end

      r = []
      pipe = PRuby.pipeline_source(1..N) | (p1 | (p1 | p1) | p1) | p1 | PRuby.pipeline_sink(r)
      pipe.run(:NO_WAIT)

      r.size.wont_equal N

      pipe.join
      r.size.must_equal N
      r.must_equal (1..N).map{ |k| k + 5 }
    end
  end
end
