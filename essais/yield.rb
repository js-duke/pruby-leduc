require 'benchmark'

NB_FOIS = 1000
TAILLE = 10000

def set( a, i, x )
  a[i] = x
end

def do_it(i)
  yield(i)
end

def do_it_explicit(i, &block)
  block.call(i)
end

a = Array.new( TAILLE )

Benchmark.bm(10) do |x|

  x.report( "each_index") do
    a = Array.new( TAILLE )
    NB_FOIS.times do
      a.each_index do |i|
        set a, i, i
      end
    end
    puts "PAS ok" unless a == [*0...TAILLE]
  end

  x.report( "yield 1") do
    a = Array.new( TAILLE )
    NB_FOIS.times do
      a.each_index do |i|
        do_it(i) do |j|
          set a, j, j
        end
      end
    end
    puts "PAS ok" unless a == [*0...TAILLE]
  end

  x.report( "yield 2") do
    a = Array.new( TAILLE )
    NB_FOIS.times do
      a.each_index do |i|
        do_it(i) do |j|
          do_it(j) do |k|
            set a, k, k
          end
        end
      end
    end
    puts "PAS ok" unless a == [*0...TAILLE]
  end

  x.report( "yield 3") do
    a = Array.new( TAILLE )
    NB_FOIS.times do
      a.each_index do |i|
        do_it(i) do |j|
          do_it(j) do |k|
            do_it(k) do |l|
              set a, l, l
            end
          end
        end
      end
    end
    puts "PAS ok" unless a == [*0...TAILLE]
  end

  x.report( "explicit 1") do
    a = Array.new( TAILLE )
    NB_FOIS.times do
      a.each_index do |i|
        do_it_explicit(i) do |j|
          set a, j, j
        end
      end
    end
    puts "PAS ok" unless a == [*0...TAILLE]
  end

  x.report( "explicit 2") do
    a = Array.new( TAILLE )
    NB_FOIS.times do
      a.each_index do |i|
        do_it_explicit(i) do |j|
          do_it_explicit(j) do |k|
            set a, k, k
          end
        end
      end
    end
    puts "PAS ok" unless a == [*0...TAILLE]
  end

  x.report( "explicit 3") do
    a = Array.new( TAILLE )
    NB_FOIS.times do
      a.each_index do |i|
        do_it_explicit(i) do |j|
          do_it_explicit(j) do |k|
            do_it_explicit(k) do |l|
              set a, l, l
            end
          end
        end
      end
    end
    puts "PAS ok" unless a == [*0...TAILLE]
  end
end
