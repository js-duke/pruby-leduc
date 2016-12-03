require_relative 'mandelbrot'
require_relative 'image'

TAILLE = 1000 #/ 10
MAX_IT = 50   #/ 10

pixels = Matrice.new( TAILLE, TAILLE, nil, true )
Mandelbrot.generer( TAILLE, TAILLE, MAX_IT ).each_index do |i, j, v|
  pixels[j, i] = Pixel.new( 16*(v % 15), 0, 32*(v % 7) )
end

img = Image.new( "P3", TAILLE, TAILLE, 255, pixels )

img.sauvegarder( "mandelbrot.ppm" )

`display mandelbrot.ppm`
