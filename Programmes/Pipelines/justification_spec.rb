$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require_relative 'justification'

describe "probleme de justification des paragraphes" do

  describe "generer_ mots" do
    context "il n'y a aucune ligne" do
      it "ne genere aucun mot" do
        res = []
        pipeline = PRuby.pipeline_source([]) | generer_mots | PRuby.pipeline_sink(res)
        pipeline.run
        res.must_equal []
      end
    end

    context "il y a une seule ligne" do
        it "genere les mots de la ligne" do
        res = []
        pipeline = PRuby.pipeline_source(["abc def, ghi, jk. Mno.\n"]) | generer_mots | PRuby.pipeline_sink(res)
        pipeline.run
        res.must_equal ["abc", "def,", "ghi,", "jk.", "Mno."]
      end

      it "ne genere aucun mot si ligne est blanche" do
        res = []
        pipeline = PRuby.pipeline_source(["   \n"]) | generer_mots | PRuby.pipeline_sink(res)
        pipeline.run
        res.must_equal []
      end
    end

    context "il y a plusieurs lignes" do
      it "genere les mots des lignes" do
        res = []
        pipeline = PRuby.pipeline_source(["abc def %xxx, ghi, jk. Mno.\n"]) | generer_mots | PRuby.pipeline_sink(res)
        pipeline.run
        res.must_equal %w{abc def %xxx, ghi, jk. Mno.}
      end

      it "ignore les lignes toutes blanches" do
        res = []
        pipeline = PRuby.pipeline_source(["abc def, ghi, jk. Mno.\n", "   \n", "\n"]) | generer_mots | PRuby.pipeline_sink(res)
        pipeline.run
        res.must_equal %w{abc def, ghi, jk. Mno.}
      end
    end
  end

  describe "justiifer_mots" do
    context "il y a plusieurs lignes de mots" do
      it "genere une erreur si un mot est trop long" do
        lambda { justifier( 4, ["abc", "def", "ghi", "jklmnop"] ) }.
          must_raise DBC::Failure
      end

      it "met tous les blancs entres deux mots si ce sont les deux seuls mots" do
        res = justifier( 10,
                         ["abc", " %xx",  "def %xx %yy", "ghi", "  %"] )
        res.must_equal ["abc    def", "ghi"]
      end

      it "distribue uniformemement les blancs" do
        res = justifier( 11,
                         ["abc", "def", "ghi", "jklmnop %x"] )
        res.must_equal ["abc def ghi", "jklmnop"]
      end

      it "met plus de blancs au debut" do
        res = justifier( 12,
                         ["abc", "def", "ghi", "jklmnop"] )
        res.must_equal ["abc  def ghi", "jklmnop"]
      end

      it "met plus de blancs au debut" do
        res = justifier( 12,
                         ["abc", "def", "ghi", "jklmnop", "x"] )
        res.must_equal ["abc  def ghi", "jklmnop x"]
      end

    end

    it "justifie plusieurs lignes" do
      lignes = ["abc de na a  b  c de  f  f g h"," ik klm", "n o p  x xxxxxxx ", "abcde"]
      res = justifier( 8, lignes )
      res.must_equal ["abc   de", "na a b c", "de f f g", "h ik klm", "n  o p x", "xxxxxxx", "abcde"]
    end
  end
end
