$LOAD_PATH.unshift('.', 'lib')

NB_FOIS = 1

require 'jruby/profiler'
require 'pruby'

class Sommes
  def self.somme_tableaux_seq( a, b )
    c = Array.new(a.size)
    (0...a.size).each do |k|
      c[k] = a[k] + b[k]
    end

    c
  end

  def self.somme_tableaux_peach( a, b, nb_threads = PRuby.nb_threads )
    c = Array.new(a.size)
    (0...a.size).peach( nb_threads: nb_threads ) do |k|
      c[k] = a[k] + b[k]
    end

    c
  end

  def self.somme_tableaux_pmap( a, b, nb_threads = PRuby.nb_threads )
    c = (0...a.size).pmap( nb_threads: nb_threads ) do |k|
      a[k] + b[k]
    end

    c
  end

  def self.somme_tableaux_pcall_statique( a, b, nb_threads = PRuby.nb_threads )
    #puts "somme_tableaux_pcall_statique( a, b, #{nb_threads} )"

    def self.inf( k, n, nbThreads )
      k * n / nbThreads
    end

    def self.sup( k, n, nbThreads )
      (k+1) * n / nbThreads - 1
    end

    def self.somme_seq( a, b, c, i, j )
      #puts "somme_seq( a, b, c, #{i}, #{j} )"
      (i..j).each do |k|
        c[k] = a[k] + b[k]
      end
    end

    DBC.require( a.size % nb_threads == 0,
                 "*** Taille incorrecte: a.size = #{a.size}, " +
                 "nb_threads = #{nb_threads}" )

    c = Array.new(a.size)

    PRuby.pcall\
    (0...nb_threads), lambda { |k|
      self.somme_seq( a,
                      b,
                      c,
                      self.inf(k, a.size, nb_threads),
                      self.sup(k, a.size, nb_threads)
                      )
    }

    c
  end

  def self.somme_tableaux_pcall_cyclique( a, b, nb_threads = PRuby.nb_threads )
    def self.somme_seq_cyclique( a, b, c, num_thread, nb_threads )
      #puts "somme_seq_cyclique( a, b, c, #{num_thread}, #{nb_threads} )"
      num_thread.step( a.size-1, nb_threads ).each do |k|
        c[k] = a[k] + b[k]
      end
    end

    c = Array.new( a.size )

    PRuby.pcall\
    (0...nb_threads), lambda { |num_thread|
      #puts "call to somme_seq_cyclique"
      self.somme_seq_cyclique( a, b, c, num_thread, nb_threads )
    }

    c
  end
end

sommes =  Sommes.methods(false).sort { |x, y| "#{x}" <=> "#{y}" }

sommes.
  reject! { |m| "#{m}" =~ /somme_tableaux_seq/ }.
  reject! { |m| "#{m}" =~ /cyclique/ }.
  reject! { |m| "#{m}" =~ /pmap/ }

def run_it( somme, a, b, nb_threads = PRuby.nb_threads )
  NB_FOIS.times do
    if somme == :somme_tableaux_seq
      Sommes.send somme, a, b
    else
      Sommes.send somme, a, b, nb_threads
    end
  end
end

n = PRuby.nb_threads * 100000
a = Array.new(n) { 1 }
b = Array.new(n) { 1 }

[4].each do |nb_threads|
  #profile_data = JRuby::Profiler.profile do
  sommes.each do |somme|
    run_it( somme, a, b, nb_threads )
  end
  #end
  #profile_printer = JRuby::Profiler::GraphProfilePrinter.new(profile_data)
  #profile_printer.printProfile(STDOUT)
end
