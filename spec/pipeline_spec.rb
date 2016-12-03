require_relative 'spec_helper'
require 'pruby'

describe PRuby do
  describe ".pipeline" do
    describe "les cas d'erreur" do
      it "signale une erreur si aucun element n'est specifie" do
        lambda { PRuby.pipeline.run }.must_raise DBC::Failure
      end

      it "signale une erreur si un lambda n'a pas deux arguments pour les canaux" do
        lambda { PRuby.pipeline( lambda { 20 } ) }.must_raise DBC::Failure
        lambda { PRuby.pipeline( lambda { |x| 2*x } ) }.must_raise DBC::Failure
      end
    end

    describe ".source" do
      it "genere une serie de valeurs a partir d'un range" do
        res = nil
        cons = lambda do |cin, cout|
          res = cin.map { |v| v }
        end

        (PRuby.pipeline_source( 1..10 ) | cons).run

        res.must_equal (1..10).to_a
      end

      it "genere une serie de valeurs a partir d'un tableau" do
        res = nil
        cons = lambda do |cin, cout|
          res = cin.map { |v| v }
        end

        (PRuby.pipeline_source( (1..10).to_a ) >> cons).run

        res.must_equal (1..10).to_a
      end

      it "genere une serie de valeurs a partir d'une chaine" do
        res = []
        (PRuby.pipeline_source("foo.txt") | PRuby.pipeline_sink(res)).run

        res.must_equal "foo.txt".each_char.to_a
      end

      it "genere une serie de valeurs a partir d'un fichier existant" do
        File.open( "foo.txt", "w+" ) do |f|
          (0..10).each { |v| f.puts v }
        end

        res = []
        (PRuby.pipeline_source("foo.txt", :file_name) | PRuby.pipeline_sink(res)).run

        res.must_equal (0..10).map { |x| "#{x}\n"}
        FileUtils.rm_f( "foo.txt" )
      end
    end

    describe ".sink" do
      it "recoit une serie de valeurs et les mets dans un tableau" do
        res = []
        (PRuby.pipeline_source(1..10) | PRuby.pipeline_sink(res)).run

        res.must_equal (1..10).to_a
      end

      it "recoit une serie de valeurs et les mets dans un fichier" do
        pipeline = PRuby.pipeline_source( 1..10 ) | PRuby.pipeline_sink( "foo.txt" )
        pipeline.run

        File.readlines( "foo.txt" ).
          map { |l| l.chomp.to_i }.
          must_equal (1..10).to_a

        FileUtils.rm_f( "foo.txt" )
      end
    end

    describe ">>" do
      it "genere des erreurs quand pas une source ou un sink" do
        bidon = lambda { |_cin, _cout| nil }
        res = nil
        lambda { PRuby.pipeline_source("foo.txt") >> bidon }.call
        lambda { (bidon | bidon) >> bidon }.call

        pipeline1 = (bidon | bidon).wrap_around!
        pipeline2 = (bidon | bidon).wrap_around!
        lambda { pipeline1 >> pipeline2 }.must_raise DBC::Failure
      end
    end

    describe "divers cas simples" do
      it "retourne comme resultat la liste des resultats" do
        pipe = PRuby.pipeline *((0..100).map { |i| lambda { |_cin, _cout| i } })
        pipe.run
        pipe.value.must_equal (0..100).to_a
      end

      it "retourne comme resultat la liste des resultats, meme si nil" do
        l1 = lambda { |_cin, _cout| nil }
        pipe = l1 | l1
        pipe.run
        pipe.value.must_equal [nil, nil]
      end

      it "traite un simple lien entre producteur et consommateur et montre que le resultat retourne est la liste des resultats" do
        prod = lambda do |_cin, cout|
          (1..10).each { |i| cout << i }
          cout.close
        end

        res = nil
        cons = lambda do |cin, _cout|
          res = cin.map { |v| v }
        end

        # Autre facon: run_res = PRuby.pipeline(prod).add_stage(cons).run
        run_res = (prod | cons).run

        res.must_equal (1..10).to_a
      end

      it "traite le cas avec plusieurs etapes et traite les lectures/ecritures multiples" do
        prod = lambda do |_cin, cout|
          (1..10).each { |i| cout << i }
          cout.close
        end

        stutter = lambda do |cin, cout|
          cin.each do |v|
            cout << v
            cout << 10*v
            cout << v
            cout << 10*v
          end
          cout.close
        end

        somme = lambda do |cin, cout|
          cin.each { |v| cout << v + cin.get }
          cout.close
        end

        r = nil
        cons = lambda do |cin, _cout|
          r = cin.map { |v| v }
        end

        (prod | stutter | somme | cons).run
        r.must_equal (1..10).map{ |i| [11*i, 11*i] }.flatten
      end

      it "traite le cas avec plusieurs etapes et traite les lectures/ecritures multiples, avec source et sink" do
        prod = PRuby.pipeline_source 1..10

        stutter = lambda do |cin, cout|
          cin.each do |v|
            cout << v
            cout << 10*v
            cout << v
            cout << 10*v
          end
          cout.close
        end

        somme = lambda do |cin, cout|
          cin.each { |v|  cout << v + cin.get }
          cout.close
        end

        r = []
        cons = PRuby.pipeline_sink r

        (prod | stutter | somme | cons).run
        r.must_equal (1..10).map{ |i| [11*i, 11*i] }.flatten
      end
    end
  end
end
