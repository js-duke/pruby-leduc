$LOAD_PATH.unshift('~/pruby/lib')
require 'mandelbrot'

java_alias :background_int, :background, [Java::int]
java_alias :color_int, :color, [Java::int, Java::int, Java::int]

TAILLE = 100 # / 10
MAX_IT = 10  # / 10

def setup
  size TAILLE, TAILLE
  background_int Mandelbrot::MAX_COULEUR
  smooth
end

def draw
  mc =  Mandelbrot::MAX_COULEUR
  load_pixels
  Mandelbrot.generer( TAILLE, TAILLE, MAX_IT ).each_index do |i, j, v|
    #c = color_int( 16*(v % 15), 0, 32*(v % 7) )

    if v == mc
      c = color_int( 0, 0, 0 )
    else
      c = color_int( 16*(v % 15), 0, 32*(v % 7) )
    end

    # Ce qui suit est equivalent, mais plus rapide semble-t-il, a
    # l'instruction "set( i, j, c )".
    pixels[j*TAILLE+i] = c
  end
  update_pixels
end
