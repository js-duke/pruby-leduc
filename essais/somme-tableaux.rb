$LOAD_PATH.unshift('.', 'lib')

require 'benchmark'
require 'pruby'
require 'forkjoin'

nb = ARGV[0] || 1000   # Valeur maximum = 2000, sinon threads pas crees

class SommeFJ < ForkJoin::Task
  def initialize(a, b, c, i, j)
    @a, @b, @c, @i, @j = a, b, c, i, j
  end

  def call
    if @i == @j
      @c[@i] = @a[@i] + @b[@i]
      return
    end

    mid = (@i+@j) / 2

    (f1 = SommeFJ.new(@a, @b, @c, @i, mid)).fork
    (f2 = SommeFJ.new(@a, @b, @c, mid+1, @j)).fork
    f1.join
    f2.join
  end
end

class Sommes
  def self.rec( a, b, c, i, j )
    if i == j
      c[i] = a[i] + b[i]
    else
      m  = (i+j) / 2
      rec(a, b, c, i, m)
      rec(a, b, c, m+1, j)
    end
  end

  def self.rec_rthread( a, b, c, i, j )
    PRuby.thread_kind = :THREAD

    if i == j
      c[i] = a[i] + b[i]
    else
      m  = (i+j) / 2
      PRuby.pcall\
      -> { rec_rthread(a, b, c, i, m) },
      -> { rec_rthread(a, b, c, m+1, j) }
    end
  end

  def self.rec_fjthread( a, b, c, i, j )
    def self._rec_fjthread( a, b, c, i, j )
      if i == j
        c[i] = a[i] + b[i]
      else
        m  = (i+j) / 2
        PRuby.pcall\
        -> { _rec_fjthread(a, b, c, i, m) },
        -> { _rec_fjthread(a, b, c, m+1, j) }
      end
    end

    PRuby.thread_kind = :FORK_JOIN_TASK
    _rec_fjthread( a, b, c, i, j )
  end

  def self.rec_sommefj( a, b, c, i, j )
    ForkJoin::Pool.new.invoke( SommeFJ.new(a, b, c, i, j) )
  end

  def self.iter( a, b, c, i, j )
    (i..j).each do |k|
      c[k] = a[k] + b[k]
    end
  end

  def self.iter_rthread( a, b, c, i, j )
    PRuby.thread_kind = :THREAD
    iters = (i..j).map { |k| -> { c[k] = a[k] + b[k]} }
    PRuby.pcall *iters
  end

  def self.iter_fjthread( a, b, c, i, j )
    PRuby.thread_kind = :FORK_JOIN_TASK
    iters = (i..j).map { |k| -> { c[k] = a[k] + b[k]} }
    PRuby.pcall *iters
  end

  def self.iter_adj_fjthread( a, b, c, i, j )
    PRuby.thread_kind = :FORK_JOIN_TASK

    nb_threads = 10
    nb = (j-i+1) / nb_threads
    iters = (0...nb_threads).map do
      |k| -> { low = k*nb; high = low+nb-1; (low..high).each { |l|  c[l] = a[l] + b[l] } }
    end
    PRuby.pcall *iters
  end

  def self.iter_adj_rthread( a, b, c, i, j )
    nb_threads = 10
    nb = (j-i+1) / nb_threads
    iters = (0...nb_threads).map do
      |k| -> { low = k*nb; high = low+nb-1; (low..high).each { |l|  c[l] = a[l] + b[l] } }
    end
    PRuby.pcall *iters
  end

end

sommes = Sommes.methods(false).sort { |x, y| "#{x}" <=> "#{y}" }

nb_espaces = sommes.map { |v| "#{v}".size }.max + 2

Benchmark.bm(nb_espaces) do |bm|
  sommes.each do |somme|
    a = (0...nb).map { |i| i }
    b = (0...nb).map { |i| 10*i }
    c = (0...nb).map { |i| nil }

    bm.report( "#{somme}: " ) { r = Sommes.send somme, a, b, c, 0, nb-1 }

    ok = true
    (0...nb).each do |k|
      if c[k] != a[k] + b[k]
        puts "Pas ok pour #{somme}: c[#{k}] = #{c[k]}" if ok
        ok = false
      end
    end
  end
end
