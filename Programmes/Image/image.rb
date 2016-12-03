$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

# Une image couleur representee par un bitmap de pixels (modele RGB).
#
# Plus specifiquement, il s'agit d'images lues et sauvegardees en
# format PPM -- _Portable_ _Pix_ _Map_.
#
# De telles images peuvent etre encodees dans des fichiers de deux
# types:
#
# - ASCII: chaque pixel est represente par un triplet de nombres
#   entiers, chaque ligne de l'image etant representee sur une ligne de
#   fichier
#
# - Binaire: chaque pixel est presente par trois octets binaires et
#   les pixels sont stockes les uns a la suite des autres.a
#
# Dans les deux cas, les trois premieres lignes du fichier contiennent
# les memes informations, sous forme ASCII:
#
# 1. Le mode du fichier: P3 => fichier ASCII; P6 => fichier binaire
# 2. Le nombre de lignes et nombre de colonnes de l'image
# 3. Le nombre de couleurs
#
# Dans les deux types de fichiers, les trois premiers nombres
# representent donc le pixel a la ligne 0/colonne 0, les trois nombres
# suivants le pixel a la ligne 0/colonne 1, etc.
#
# Des lignes debutant par "\#" peuvent aussi etre presentes, et elles
# indiquent alors des commentaires.
#
# Ce format a ete utilise parce que simple -- bien que pas
# necessairement efficace car il n'y a aucune compression de
# donnees. Par contre, de nombreux outils sont disponibles sur Linux
# pour convertir des images du format PPM a d'autres formats, et
# vice-versa:
#
# - ppmtojpeg
# - ppmtogif
# - jpegtopnm
# - giftopnm
#
class Image

  # Constantes pour acceder aux differentes couleurs d'un pixel.
  RED = 0
  GREEN = 1
  BLUE = 2
  RED_GREEN_BLUE = [RED, GREEN, BLUE]

  # @return [String]
  attr_reader :mode

  # @return [Array<Fixnum>]
  attr_reader :pixels

  # @return [Fixnum]
  attr_reader :nb_lignes, :nb_colonnes, :nb_couleurs

  # Creation d'une image
  #
  # @param [String] mode
  # @param [Fixnum] nb_lignes
  # @param [Fixnum] nb_colonnes
  # @param [Fixnum] nb_couleurs
  # @param [Array<Fixnum>] pixels
  #
  # @require nb_lignes > 0 && nb_colonnes > 0
  # @require nb_couleurs > 0
  # @require mode == "P3" || mode == "P6"
  # @require pixels.size = 3 * nb_lignes * nb_colonnes
  #
  # @return [Image]
  #
  def initialize( mode, nb_lignes, nb_colonnes, nb_couleurs, pixels )
    DBC.require (mode =~ /P[36]/)
    DBC.require nb_lignes > 0
    DBC.require nb_colonnes > 0
    DBC.require nb_couleurs > 0
    DBC.require pixels.size == 3 * nb_lignes * nb_colonnes

    @mode = mode
    @nb_lignes = nb_lignes
    @nb_colonnes = nb_colonnes
    @nb_couleurs = nb_couleurs
    @pixels = pixels
  end

  # Cree une image .ppm a partir du contenu d'un fichier
  #
  # @param [String] nom du fichier
  #
  # @require Le fichier doit etre un fichier PPM en mode P3 ou P6
  #
  # @return [Image] l'image creee
  #
  def self.ouvrir( fich )
    File.open( fich ) do |fich|
      mode = lire_ligne( fich )
      DBC.require ['P3', 'P6'].include?(mode)

      nb_lignes, nb_colonnes = lire_ligne(fich).split(' ').map(&:to_i)
      nb_couleurs = lire_ligne(fich).to_i

      img = Image.new( mode,
                       nb_lignes, nb_colonnes,
                       nb_couleurs,
                       Array.new( 3 * nb_lignes * nb_colonnes ) )

      nb_lignes.times do |i|
        vals = lire_ligne(fich).split(' ').map(&:to_i) if img.ascii?
        nb_colonnes.times do |j|
          if img.ascii?
            red_green_blue = vals[3*j+RED], vals[3*j+GREEN], vals[3*j+BLUE]
          else
            red_green_blue = fich.read(3).unpack('C3')
          end
          RED_GREEN_BLUE.each do |c|
            img.set_pixel( i, j, c, red_green_blue[c] )
          end
        end
      end

      img
    end
  end

  # Sauvegarde d'une image dans un fichier.
  #
  # @param [String] fich nom du fichier
  # @return [void]
  # @ensure L'image a ete sauvegardee dans le format initiale
  #
  def sauvegarder( fich )
    File.open( fich, 'w' ) do |fich|
      fich.puts mode
      fich.puts "#{nb_lignes} #{nb_colonnes}"
      fich.puts "#{nb_couleurs}"

      fich.binmode if mode == 'P6'

      nb_lignes.times do |i|
        nb_colonnes.times do |j|
          rgb = [red(i, j), green(i, j), blue(i, j)]
          if ascii?
            le_pixel = rgb.map(&:to_s).join(' ') << ' '
          else
            le_pixel = rgb.pack('C3')
          end
          fich.print le_pixel
        end
        fich.puts if ascii?
      end
    end
  end

  # Determine si deux images sont identiques.
  #
  # @param [Image] autre l'autre image a comparer
  # @return [Bool] true ssi tous les champs, y compris le mode, sont identiques
  #
  def ==( autre )
    return false unless mode == autre.mode
    return false unless nb_lignes == autre.nb_lignes
    return false unless nb_colonnes == autre.nb_colonnes
    return false unless nb_couleurs == autre.nb_couleurs

    nb_lignes.times do |i|
      nb_colonnes.times do |j|
        unless red(i, j) == autre.red(i, j) &&
            green(i, j) == autre.green(i, j) &&
            blue(i, j) == autre.blue(i, j)
          return false
        end
      end
    end

    true
  end

  # Iterateur pour chacun des pixels.
  #
  # @yieldparam [Pixel] pixel un des pixels a traiter
  # @yieldreturn [void]
  #
  def each
    nb_lignes.times do |i|
      nb_colonnes.times do |j|
        yield red(i, j), green(i, j), blue(i, j)
      end
    end
  end

  def index( i, j, color )
    3 * (i * nb_lignes + j) + color
  end

  def pixel( i, j, color )
    pixels[3 * (i * nb_lignes + j) + color]
  end

  def set_pixel( i, j, color, c )
    pixels[3 * (i * nb_lignes + j) + color] = c
  end

  def red( i, j )
    pixels[3 * (i * nb_lignes + j) + RED]
  end

  def green( i, j )
    pixels[3 * (i * nb_lignes + j) + GREEN]
  end

  def blue( i, j )
    pixels[3 * (i * nb_lignes + j) + BLUE]
  end

  # Gonfle une image.
  #
  # @param [Numeric] nb_fois facteur de gonflement
  # @return [self]
  # @ensure l'image a ete modifiee
  #
  def gonfler( nb_fois = 2 )
    nb_lignes2 = nb_fois * nb_lignes
    nb_colonnes2 = nb_fois * nb_colonnes
    pixels2 = Array.new( 3 * nb_lignes2 * nb_colonnes2 )

    nb_lignes2.times do |i|
      nb_colonnes2.times do |j|
        RED_GREEN_BLUE.each do |c|
          pixels2[index(i, j, c)] = pixel(i / nb_fois, j / nb_fois, c)
        end
      end
    end

    @nb_lignes = nb_lignes2
    @nb_colonnes = nb_colonnes2
    @pixels = pixels2

    self
  end

  # Blur une image.
  #
  # @return [self]
  # @ensure l'image a ete blurre
  #
  def blur
    pixels2 = Matrice.new( nb_lignes, nb_colonnes )

    (0...nb_lignes).each do |i|
      p = pixels[i, 0]
      pixels2[i, 0] = Pixel.new( p.red, p.green, p.blue )
      p = pixels[i, nb_colonnes-1]
      pixels2[i, nb_colonnes-1] = Pixel.new( p.red, p.green, p.blue )
    end
    (0...nb_colonnes).each do |j|
      p = pixels[0, j]
      pixels2[0, j] = Pixel.new( p.red, p.green, p.blue )
      p = pixels[nb_lignes-1, j]
      pixels2[nb_lignes-1, j] = Pixel.new( p.red, p.green, p.blue )
    end

    (1...nb_lignes-1).each do |i|
      (1...nb_colonnes-1).each do |j|
        top = pixels[i, j-1]
        bottom = pixels[i, j+1]
        left = pixels[i-1, j]
        right = pixels[i, j-1]
        center = pixels[i,j]
        points = [top, bottom, left, right, center]

        red = points.map(&:red).reduce(:+) / 5
        green = points.map(&:green).reduce(:+) / 5
        blue = points.map(&:blue).reduce(:+) / 5

        pixels2[i, j] = Pixel.new( red, green, blue )
      end
    end

    @pixels = pixels2
    self
  end

  # Inverse les couleurs d'une image.
  #
  # @return [self]
  # @ensure l'image a ete inversee
  #
  def negatif
    (0...nb_lignes).each do |i|
      (0...nb_colonnes).each do |j|
        RED_GREEN_BLUE.each do |c|
          pixels[index(i, j, c)] = nb_couleurs - pixel(i, j, c)
        end
      end
    end
  end

  # Chaine representant certaines informations cles d'une image (pas
  # les pixels!)
  #
  # @return [String]
  #
  def to_s
    "#<Image:#{object_id} [#@mode]:  #@nb_lignes X #@nb_colonnes (#@couleurs)}>"
  end

  # Indique si le mode initial du fichier etait ASCII
  #
  # @return [Bool]
  def ascii?
    @mode == 'P3'
  end

  def self.lire_ligne( fich )
    while (ligne = fich.gets) =~ /^\#/; end
    ligne.chomp
  end
end
