$LOAD_PATH.unshift('../../spec')

require 'spec_helper'
require 'pruby'
require_relative 'depot-git'

describe DepotGit do
  let(:depot_pruby) { "#{ENV['HOME']}/pruby" }
  let(:depot_big_data) { "#{ENV['HOME']}/UniTo_UQAM" }

  describe ".open et #each_commit" do
    it "ouvre le log du depot pour pruby et permet d'acceder aux divers commits" do
      commits = []
      git = DepotGit.open depot_pruby
      git.each_commit do |commit|
        commits << commit
      end

      assert commits.size > 500
      commits.last.commit.must_equal "8f83f5a242ae5c0670fb0a1ac9126275a34d96e5"
      commits.last.auteur.must_equal "Guy Tremblay"
      commits.last.date.must_equal "May 5 2015"
      commits.last.heure.must_equal "09:48:28"
    end

  end

  it "peut etre utilise comme source d'un stream" do
    PRuby::Stream.source( DepotGit.open depot_pruby )
      .drop(400)
      .to_a
      .last.commit.must_equal "8f83f5a242ae5c0670fb0a1ac9126275a34d96e5"
  end

  describe "divers exemples manipulant le log du depot git" do
    it "retourne les differents commiteurs" do
      PRuby::Stream.source( DepotGit.open depot_pruby )
        .map(&:auteur)
        .sort
        .uniq
        .to_a
        .must_equal ["Guy Tremblay"]
    end

    it "retourne le nombre de commits de chaque date en ordre decroissant" do
      res = PRuby::Stream.source( DepotGit.open depot_pruby )
        .group_by(&:date)
        .map { |p| [p.first, p.last.count] }
        .sort { |p1, p2| p2.last <=> p1.last }
        .to_a

      res.map(&:last)
        .reduce(:+)
        .must_be :>=, 495
    end

    it "retourne la date ou il y a eu le plus de commits" do
      res = PRuby::Stream.source( DepotGit.open depot_pruby )
        .group_by(&:date)
        .map { |p| [p.first, p.last.count] }
        .sort { |p1, p2| p2.last <=> p1.last }
        .take(1)
        .map(&:first)
        .to_a

      res.must_equal ["Jun 12 2015"]
    end

    describe "#commiteurs" do
      it "retourne les divers commiteurs en ordre croissant pour PRuby" do
        DepotGit.open( depot_pruby )
          .commiteurs
          .must_equal ["Guy Tremblay"]
      end

      it "retourne les divers commiteurs en ordre croissant pour l'article Big Data" do
        DepotGit.open( depot_big_data )
          .commiteurs
          .must_equal ["Claudia Misale",
                       "Guy Tremblay",
                       "Marco Aldinucci",
                       "Maurizio Drocco",
                       "drocco",
                       "misale"]
      end
    end

    describe "#commits_par_commiteur" do
      it "retourne les divers commits des commiteurs pour PRuby" do
        auteur, nb = DepotGit.open( depot_pruby )
          .commits_par_commiteur
          .first

        auteur.must_equal "Guy Tremblay"
        nb.must_be :>, 500
      end

      it "retourne les divers commits des commiteurs pour Big Data" do
        DepotGit.open( depot_big_data )
          .commits_par_commiteur
          .must_equal [["Guy Tremblay", 20],
                       ["drocco", 16],
                       ["Marco Aldinucci", 8],
                       ["misale", 7],
                       ["Maurizio Drocco", 4],
                       ["Claudia Misale", 1]]
      end
    end
  end

  describe "#commits_par_date" do
    it "retourne le nombre de commits de chaque date en ordre decroissant pour PRuby" do
      res = DepotGit.open( depot_pruby )
        .commits_par_date

      res.map(&:last)
        .reduce(:+)
        .must_be :>=, 495
    end

    it "retourne le nombre de commits de chaque date en ordre decroissant pour Big Data" do
      DepotGit.open( depot_big_data )
        .commits_par_date
        .must_equal [["2016-05-01", 14],
                     ["2016-04-28", 11],
                     ["2016-04-27", 11],
                     ["2016-04-29", 8],
                     ["2016-04-26", 6],
                     ["2016-04-30", 5],
                     ["2016-05-02", 1],
                    ]
    end
  end

  describe "#commits_par_mois" do
    it "retourne le nombre de commits de chaque date en ordre decroissant pour Big Data" do
      DepotGit.open( depot_big_data )
        .commits_par_mois
        .must_equal ["2016/4 => 41",
                     "2016/5 => 15",
                    ]
    end
  end
end
