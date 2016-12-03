require_relative 'spec_helper'
require 'pruby'

module PRuby
  SLEEP = 0.2

  describe Channel do

    before do
      @c = Channel.new
    end

    describe ".new" do
      it "sets and gets the specific name" do
        c = Channel.new("Foo")
        c.to_s.must_match /^Foo/
      end
    end

    describe "#peek" do
      it "does not move the channel head" do
        c = Channel.new nil, 0, [10, 20, EOS]

        assert_equal 10, c.peek
        assert_equal 10, c.peek
        assert_equal 10, c.get
        assert_equal 20, c.peek
        assert_equal 20, c.peek
        assert_equal 20, c.get
        assert_equal EOS, c.peek
        assert_equal EOS, c.peek
        assert_equal EOS, c.get
        assert_equal EOS, c.get
      end
    end

    describe "#get" do
      it "moves the channel head" do
        c = Channel.new nil, 0, [10, 20, 30, EOS]

        assert_equal 10, c.get
        assert_equal 20, c.get
        assert_equal 30, c.get
        assert_equal EOS, c.get
      end

      it "always reads EOS once it is seen" do
        @c.close

        assert_equal EOS, @c.get
        assert_equal EOS, @c.get
        assert_equal EOS, @c.get
      end

    end

    describe "#put/#get done concurrently" do
      it "blocks on an empty channel and unblocks if EOS is written" do
        t1 = Thread.new do
          sleep 2*SLEEP
          @c.close
        end

        t2 = Thread.new do
          assert_equal EOS, @c.get
        end

        t1.join
        t2.join
      end

      it "blocks on an empty channel and unblocks once something is written" do
        t1 = Thread.new do
          sleep SLEEP
          @c.put 10
          @c.close
        end

        t2 = Thread.new do
          assert_equal 10, @c.get
          assert_equal EOS, @c.get
          assert_equal EOS, @c.get
        end

        t1.join
        t2.join
      end

      it "handles multiple puts" do
        t1 = Thread.new do
          sleep SLEEP
          @c.put 10
          sleep SLEEP
          @c.put 20
          sleep SLEEP
          @c.put 30
          @c.close
        end

        t2 = Thread.new do
          assert_equal 10, @c.get
          assert_equal 20, @c.get
          assert_equal 30, @c.get
          assert_equal EOS, @c.get
          assert_equal EOS, @c.get
        end

        t1.join
        t2.join
      end

      it "handles multiple concurrent puts" do
        t0 = Thread.new do
          @c.put 10
          @c.put 10
        end

        t1 = Thread.new do
          sleep SLEEP
          @c.put 10
          sleep SLEEP
          @c.put 10
          @c.put 10
          @c.close
        end

        t2 = Thread.new do
          assert_equal 10, @c.get
          assert_equal 10, @c.get
          assert_equal 10, @c.get
          assert_equal 10, @c.get
          assert_equal 10, @c.get
          assert_equal EOS, @c.get
          assert_equal EOS, @c.get
        end

        t0.join
        t1.join
        t2.join
      end

      it "handles multiple concurrent puts and gets the right contents after all puts are done" do
        @c.put 10
        @c.put 10
        @c.close

        t2 = Thread.new do
          sleep SLEEP
          assert_equal [10, 10, EOS], @c.get_all(true)
          assert_equal [10, 10], @c.get_all
          assert_equal EOS, @c.get
        end

        t2.join
      end
    end

    describe "#put" do
      it "handles multiple concurrent puts and gets the right contents even when not all puts are done yet" do
        t1 = Thread.new do
          sleep SLEEP
          @c.put 10
          sleep SLEEP
          @c.put 10
          sleep SLEEP
          @c.close
        end

        assert_equal [10, 10], @c.get_all
        assert_equal EOS, @c.get

        t1.join
      end
    end

    describe "autres cas" do
      it "put suspends when channel is full until space becomes available" do
        Thread.abort_on_exception = true
        c = Channel.new nil, 2
        c.put 10
        c.put 20
        c.full?.must_equal true
        Thread.new do
          sleep SLEEP
          assert_equal 10, c.get
          assert_equal 20, c.get
          assert_equal 30, c.get
        end
        c.put 30
        c.put 40
        c.put 50
        c.get.must_equal 40
        c.get.must_equal 50
      end

      it "waits for multiple EOS" do
        ch = Channel.new.with_multiple_writers(3)

        ch.close
        ch.put 10
        ch.close
        ch.put 20
        ch.put 30
        ch.close
        lambda { ch.put 40 }.must_raise DBC::Failure

        ch.get.must_equal 10
        ch.get.must_equal 20
        ch.get.must_equal 30
        ch.get.must_equal EOS
        ch.get.must_equal EOS
      end

      it "waits for multiple EOS with real multiple writers" do
        ch = Channel.new.with_multiple_writers(2)

        Thread.new { sleep SLEEP; ch.put 100; ch.close }

        Thread.new { ch.put 10; ch.put 20; ch.put 30; ch.close }

        ch.get.must_equal 10
        ch.get.must_equal 20
        ch.get.must_equal 30
        ch.get.must_equal 100
        ch.get.must_equal EOS
        ch.get.must_equal EOS
      end
    end

    describe "#close" do
      let(:ch) { Channel.new }

      it "ferme le canal donc assure qu'il retourne EOS" do
        ch.put 10
        ch.close

        ch.get.must_equal 10
        ch.get.must_equal EOS
      end

      it "ferme le canal et signale une erreur si on fait un autre put" do
        ch.put 10
        ch.close
        assert ch.closed?
        proc { ch.put 20 }.must_raise DBC::Failure
      end
    end
  end
end
