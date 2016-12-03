$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'image'

TAILLE_IMAGE_TEST = 64
IMAGE_TEST = "image-test-#{TAILLE_IMAGE_TEST}"

describe Image do
  describe ".ouvrir" do
    it "lit le fichier ASCII #{IMAGE_TEST}.ppm" do
      img = Image.ouvrir( "./#{IMAGE_TEST}.ppm" )
      img.nb_lignes.must_equal TAILLE_IMAGE_TEST
      img.nb_colonnes.must_equal TAILLE_IMAGE_TEST
      img.nb_couleurs.must_equal 255

      (0...TAILLE_IMAGE_TEST).each do |i|
        (0...TAILLE_IMAGE_TEST).each do |j|
          assert_equal img.red(i, j), i
          assert_equal img.green(i, j), i
          assert_equal img.blue(i, j), i
        end
      end
    end
  end

  describe "#sauvegarder" do
    it "lit le fichier ASCII #{IMAGE_TEST}.ppm" do
      img = Image.ouvrir( "./#{IMAGE_TEST}.ppm" )
      img.sauvegarder( "./#{IMAGE_TEST}-bis.ppm" )

      img_bis = Image.ouvrir( "./#{IMAGE_TEST}-bis.ppm" )
      assert_equal img, img_bis

      FileUtils.rm_f "./#{IMAGE_TEST}-bis.ppm"
    end
  end

  describe "#==" do
    it "retourne vrai pour soi-meme" do
      img = Image.ouvrir( "./#{IMAGE_TEST}.ppm" )
      assert_equal img, img
    end

    it "retourne vrai pour une meme image chargee deux fois" do
      img1 = Image.ouvrir( "./#{IMAGE_TEST}.ppm" )
      img2 = Image.ouvrir( "./#{IMAGE_TEST}.ppm" )
      assert_equal img1, img2
      assert_equal img2, img1
    end
  end

  describe "#gonfler" do
    it "produit une image deux fois plus grosse" do
      NB_FOIS = 2

      img1 = Image.ouvrir( "./#{IMAGE_TEST}.ppm" )

      nb_lignes = img1.nb_lignes
      nb_colonnes = img1.nb_colonnes

      img1.gonfler( NB_FOIS )
      img1.sauvegarder( "./#{IMAGE_TEST}-gonfle-2.ppm" )

      img1.nb_lignes.must_equal NB_FOIS * nb_lignes
      img1.nb_colonnes.must_equal NB_FOIS * nb_colonnes
    end
  end

  describe "#negatif" do
    it "produit une image en negatif du fichier de test" do
      img1 = Image.ouvrir( "./#{IMAGE_TEST}.ppm" )
      img1.negatif

      img2 = Image.ouvrir( "./#{IMAGE_TEST}-negatif.ppm" )

      assert_equal img2, img1
    end
  end

  _describe "#blur" do
    it "produit une image deux fois plus grosse mais avec un blur approprie" do
      img1 = Image.ouvrir( "./ball.ppm" )

      nb_lignes = img1.nb_lignes
      nb_colonnes = img1.nb_colonnes

      puts "Appel a gonfler"
      img1.gonfler( NB_FOIS )

      puts "Appel a blur"
      img1.blur

      img1.sauvegarder( "./ball-gonfle-blur.ppm" )

      img1.nb_lignes.must_equal NB_FOIS * nb_lignes
      img1.nb_colonnes.must_equal NB_FOIS * nb_colonnes
    end
  end
end
