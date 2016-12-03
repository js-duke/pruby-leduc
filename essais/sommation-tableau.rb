$LOAD_PATH.unshift('.', 'lib')

require 'benchmark'
require 'pruby'

# Valeur maximum sur MacBook = 2000, sinon threads pas crees

nb = ARGV[0] ? ARGV[0].to_i : 200


class SommeFJ < ForkJoin::Task
  def initialize(a, i, j)
    @a, @i, @j = a, i, j
  end

  def call
    return @a[@i] if @i == @j

    mid = (@i+@j) / 2

    (f1 = SommeFJ.new(@a, @i, mid)).fork
    (f2 = SommeFJ.new(@a, mid+1, @j)).fork
    f1.join + f2.join
  end
end

class Sommes
  def self.somme_iter( a, i, j )
    res = 0
    (i..j).each do |k|
      res += a[k]
    end
    res
  end

  def self.somme_rec( a, i, j )
    if i == j
      a[i]
    else
      m  = (i+j) / 2
      r1 = somme_rec(a, i, m)
      r2 = somme_rec(a, m+1, j)
      r1 + r2
    end
  end

  def self.somme_rec_pcall( a, i, j )
    return
    if i == j
      a[i]
    else
      m  = (i+j) / 2
      r1, r2 = nil, nil
      PRuby.pcall\
      -> { r1 = somme_rec_pcall(a, i, m) },
      -> { r2 = somme_rec_pcall(a, m+1, j) }
      r1 + r2
    end
  end

  def self.somme_rec_sommefj( a, i, j )
    ForkJoin::Pool.new.invoke( SommeFJ.new(a, i, j) )
  end

  def self.somme_rec_pcall_fj( a, i, j )
    return
    def self._somme_rec_pcall_fj( a, i, j )
      if i == j
        a[i]
      else
        m  = (i+j) / 2
        r1, r2 = nil, nil
        PRuby.pcall\
        -> { r1 = _somme_rec_pcall_fj(a, i, m) },
        -> { r2 = _somme_rec_pcall_fj(a, m+1, j) }
        r1 + r2
      end
    end

    PRuby.thread_kind = :FORK_JOIN_TASK
    _somme_rec_pcall_fj( a, i, j )
  end

  def self.somme_tableau_pcall_statique( a, i, j )
    def self.inf( k, n, nbThreads )
      k * n / nbThreads
    end

    def self.sup( k, n, nbThreads )
      (k+1) * n / nbThreads - 1
    end

    def self.somme_seq( a, i, j )
      (i..j).map { |k| a[k] }.reduce(&:+)
    end

    nb_threads = PRuby.nb_threads
    DBC.require( a.size % nb_threads == 0,
                 "*** Taille incorrecte: a.size = #{a.size}, " +
                 "nb_threads = #{nb_threads}" )

    r = Array.new(nb_threads)

    PRuby.pcall\
    (0...nb_threads), lambda { |k|
      r[k] = somme_seq( a,
                        inf(k, a.size, nb_threads),
                        sup(k, a.size, nb_threads)
                        )
    }

    r.reduce(&:+)
  end

  def self.somme_tableau_pcall_cyclique( a, i, j )
    def self.somme_seq_cyclique( a, num_thread, nb_threads )
      num_thread.step( a.size-1, nb_threads ).
        map { |k| a[k] }.
        reduce(&:+)
    end

    nb_threads = PRuby.nb_threads
    r = Array.new(nb_threads)

    PRuby.pcall\
    (0...nb_threads), lambda { |num_thread|
      r[num_thread] = somme_seq_cyclique( a, num_thread, nb_threads )
    }

    r.reduce(&:+)
  end
end

sommes =  Sommes.methods(false).sort { |x, y| "#{x}" <=> "#{y}" }

sommes.reject! { |m| "#{m}" =~ /rec/ }

attendu = nb * (nb+1) / 2

nb_espaces = sommes.map { |v| "#{v}".size }.max + 2

Benchmark.bmbm(nb_espaces) do |bm|
  sommes.each do |somme|
    a = (1..nb).map { |i| i }

    bm.report( "#{somme} (nb = #{nb}): " ) {
      r = Sommes.send somme, a, 0, nb-1
      puts "Pas OK pour #{somme}: obtenu = #{r} <> #{attendu}" unless r == attendu
    }

  end
end

=begin
Execution sur machine Linux (PRuby.nb_threads = 8)
                                                   user     system      total        real
somme_iter (nb = 200):                         0.000000   0.000000   0.000000 (  0.001000)
somme_tableau_pcall_cyclique (nb = 200):       0.010000   0.000000   0.010000 (  0.002000)
somme_tableau_pcall_statique (nb = 200):       0.020000   0.000000   0.020000 (  0.003000)

                                                   user     system      total        real
somme_iter (nb = 2000):                        0.010000   0.000000   0.010000 (  0.001000)
somme_tableau_pcall_cyclique (nb = 2000):      0.010000   0.000000   0.010000 (  0.003000)
somme_tableau_pcall_statique (nb = 2000):      0.010000   0.000000   0.010000 (  0.003000)

                                                   user     system      total        real
somme_iter (nb = 20000):                       0.020000   0.000000   0.020000 (  0.003000)
somme_tableau_pcall_cyclique (nb = 20000):     0.020000   0.000000   0.020000 (  0.004000)
somme_tableau_pcall_statique (nb = 20000):     0.030000   0.000000   0.030000 (  0.006000)

                                                   user     system      total        real
somme_iter (nb = 200000):                      0.040000   0.000000   0.040000 (  0.017000)
somme_tableau_pcall_cyclique (nb = 200000):    0.110000   0.000000   0.110000 (  0.021000)
somme_tableau_pcall_statique (nb = 200000):    0.100000   0.000000   0.100000 (  0.020000)

                                                   user     system      total        real
somme_iter (nb = 2000000):                     0.260000   0.000000   0.260000 (  0.182000)
somme_tableau_pcall_cyclique (nb = 2000000):   1.150000   0.010000   1.160000 (  0.198000)
somme_tableau_pcall_statique (nb = 2000000):   0.920000   0.010000   0.930000 (  0.151000)
=end
