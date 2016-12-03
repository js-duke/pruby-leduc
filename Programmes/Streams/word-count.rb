$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

DEBUG = false

class Array
  def stream
    PRuby::Stream.source( self )
  end

  def fst
    self[0]
  end

  def snd
    self[1]
  end
end

class Pair
  attr_reader :fst, :snd

  def initialize( fst, snd )
    @fst, @snd = fst, snd
  end

  def self.[]( fst, snd )
    new( fst, snd )
  end
end

def word_count_spark1( lines )
  PRuby::Stream.source(lines)
    .flat_map { |line| line.split( ' ' ) }
    .map { |word| [word, 1] }
    .group_by_key
    .peek { |k, v| puts "'#{k}' => #{v}" if DEBUG }
    .map { |w, occs| [w, occs.reduce(&:+)] }
    .to_a
end

def word_count_spark2( lines )
  PRuby::Stream.source(lines)
    .flat_map { |line| line.split( ' ' ) }
    .map { |word| [word, 1] }
    .reduce_by_key { |x, y| x + y }
    .to_a
end

def word_count_flink1( lines )
  PRuby::Stream.source(lines)
    .flat_map { |line| line.split( ' ' ) }
    .map { |word| [word, 1] }
    .group_by(&:fst)
    .peek { |k, v| puts "'#{k}' => #{v}" if DEBUG }
    .map { |w, occs| [w, occs.map(&:snd)] }
    .peek { |k, v| puts "'#{k}' => #{v}" if DEBUG }
    .map { |w, occs| [w, occs.reduce(&:+)] }
    .to_a
end

def word_count_flink2( lines )
  PRuby::Stream.source(lines)
    .flat_map { |line| line.split( ' ' ) }
    .map { |word| [word, 1] }
    .group_by(&:fst)
    .map { |w, occs| [w, occs.reduce(0) { |a, x| a + x.snd }] }
    .to_a
end

def word_count_flink3( lines )
  PRuby::Stream.source(lines)
    .flat_map { |line| line.split( ' ' ) }
    .map { |word| [word, 1] }
    .group_by( map_value: -> x { x.snd }, &:fst )
    .map { |w, occs| [w, occs.reduce(&:+)] }
    .to_a
end

def word_count_flink4( lines )
  PRuby::Stream.source(lines)
    .flat_map { |line| line.split( ' ' ) }
    .map { |word| [word, 1] }
    .group_by(&:fst)
    .sum_by_key(&:snd)
    .to_a
end

def word_count_java8( lines )
  PRuby::Stream.source(lines)
    .flat_map { |line| line.split( ' ' ) }
    .map { |word| [word, 1] }
    .collect_grouping_by { |w, c| w }
    .stream      # Turn back collection into a stream!
    .map { |w, occs| [w, occs.reduce(0) { |a, x| a + x.snd }] }
    .to_a
end

def word_count_flume1( lines )
  PRuby::Stream.source(lines)
    .parallel_do { |line, emitter_fn| line.split( ' ' ).each { |l| emitter_fn.emit l } }
    .parallel_do { |word, emitter_fn| emitter_fn.emit [word, 1] }
    .group_by_key
    .combine_values { |x, y| x + y }
    .to_a
end

def word_count_GDF( lines )
  PRuby::Stream.source(lines)
    .apply_( ->(line, context) { line.split( ' ' ).each { |l| context.emit l } } )
    .apply_( ->(word, context) { context.emit [word, 1] } )
    .group_by_key
    .combine_values { |x, y| x + y }
    .to_a
end

=begin
VERSION MAP REDUCE
------------------
mapper = lambda do |key, line, output|
  line.split( ' ' ).each { |word| output.emit [word, 1] }
end

reducer = lambda do |word, occs, output|
  output.emit [word, occs.reduce(:+)]
end

MapReduce.new( mapper, reducer )
         .run( input_file, output_file )

=end
