$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

module Maximum
  def maximum( s, i, j )
    if i == j
      s[i]
    else
      m = (i + j) / 2
      max1 = max2 = nil
      PRuby.pcall\
      -> { max1 = maximum( s, i, m ) },
      -> { max2 = maximum( s, m + 1, j ) }
      [max1, max2].max
    end
  end

  def maximum_( s, i, j )
    if i == j
      s[i]
    else
      m = (i + j) / 2
      max1 = PRuby.future { maximum_( s, i, m ) }
      max2 = PRuby.future { maximum_( s, m + 1, j ) }

      [max1.value, max2.value].max
    end
  end

  def inf( i, n )
    i * (n / $nb_threads)
  end

  def sup( i, n )
    inf(i + 1, n) - 1
  end

  def maximum_t( s )
    m = Array.new( $nb_threads )
    n = s.size

    threads = []
    (0...$nb_threads).each do |i|
      threads << Thread.new  do
        m[i] = s[inf(i, n)..sup(i, n)].max
      end
    end
    threads.map(&:join)

    m.max
  end

  def maximum__( s )
    m = Array.new( $nb_threads )
    n = s.size

    PRuby.pcall (0...$nb_threads),
    ->( i ) { m[i] = s[inf(i, n)..sup(i, n)].max }

    m.max
  end

  def maximum_log( s )
    # s.size doit etre une puissance de 2
    n = s.size
    s = s.clone

    for i in 0..(Math.log2 n) - 1
      dist = 2**i
      (dist-1...n).step(2*dist).to_a.peach do |j|
        s[j+dist] = [s[j], s[j+dist]].max
      end
    end
    s.last
  end

  def maximum_preduce( s )
    s.preduce( s[0] ) { |m, v| [m, v].max }
  end

end
