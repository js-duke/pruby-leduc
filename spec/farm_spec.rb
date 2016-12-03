require_relative 'spec_helper'
require 'pruby'

describe PRuby do
  describe ".pipeline avec instances multiples (farm, master/worker)" do
    it "ne peut pas y avoir un farm avec autre chose qu'un lambda" do
      source = PRuby.pipeline_source 1..10

      r = []
      sink = PRuby.pipeline_sink r

      pipe0 = -> cin, cout {} | -> cin, cout {}

      lambda { pipe = source | (pipe0 * 2) | sink }.must_raise NoMethodError
    end

    it "genere un nombre fixe, petit, de workers, qui se partagent le travail recu sur le canal" do
      NB_WORKERS = 7
      NB = 59

      source = PRuby.pipeline_source 1..NB
      r = []
      sink = PRuby.pipeline_sink r

      threads = []
      worker = lambda do |cin, cout|
        threads << Thread.current.object_id
        cin.each do |v|
          cout << [10*v, Thread.current.object_id]
          jiggle
        end
        cout.close
        :DONE
      end

      pipe = (source | (worker * NB_WORKERS) | sink)

      pipe.run

      r.map(&:first).sort.must_equal (1..NB).map { |x| 10*x }

      threads.size.must_equal NB_WORKERS
      r.map(&:last).to_set.sort.must_equal threads.sort


      pipe.value.must_equal [nil, Array.new(NB_WORKERS, :DONE), nil]
    end


    it "peut y avoir plusieurs farms les uns a la suite des autres" do
      nb = 100

      worker = lambda do |cin, cout|
        cin.each do |v|
          cout << v+1
          jiggle
        end
        cout.close
        :DONE
      end

      farm2 = worker * 2
      farm3 = worker * 3

      r = []
      pipe = PRuby.pipeline_source(1..nb) | farm2 | worker | farm3 | PRuby.pipeline_sink(r)

      pipe.run(:NO_WAIT)
      r.size.wont_equal nb

      pipe.value.must_equal [nil, [:DONE, :DONE], :DONE, [:DONE, :DONE, :DONE], nil]
      r.size.must_equal nb
      r.sort.must_equal (1..nb).map { |i| i + 3 }
    end
  end
end
