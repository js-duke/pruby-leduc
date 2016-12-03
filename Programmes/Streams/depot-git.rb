require 'date'

class Commit
  attr_reader :commit
  attr_accessor :auteur, :date, :heure

  def initialize( commit, auteur = nil, date = nil, heure = nil )
    @commit = commit
    @auteur = auteur
    @date = date
    @heure = heure
  end

  def ==( autre )
    return false unless autre.kind_of?(Commit)

    @commit == autre.commit
  end
end

class DepotGit
  attr_reader :depot

  ID_COMMIT = /\w{40}/
  LIGNE_COMMIT = /^commit\s+(#{ID_COMMIT})/

  def initialize( depot )
    @depot = depot
  end

  private_class_method :new

  def self.open( depot )
    new( depot )
  end

  def each_commit
    lignes = `git --git-dir=#{@depot}/.git log`.split("\n")
    suivant = 0
    while suivant < lignes.size
      fail "*** Pas une ligne de commit" unless LIGNE_COMMIT =~ lignes[suivant]

      LIGNE_COMMIT =~ lignes[suivant]
      commit = $1
      suivant += 1

      suivant += 1 if /Merge:/ =~ lignes[suivant]

      /Author:\s*([^<]+)\s+/ =~ lignes[suivant]
      auteur = $1.strip
      suivant += 1

      /Date:\s+\w{3}\s+(\w{3})\s(\d{1,2})\s(.*)\s(\d{4})\s.\d{4}$/ =~ lignes[suivant]
      date = "#$1 #$2 #$4"
      heure = $3
      suivant += 1

      yield Commit.new( commit, auteur, date, heure )

      suivant += 1 while suivant < lignes.size && LIGNE_COMMIT !~ lignes[suivant]
    end

  end

  alias_method :each, :each_commit

  def commit_stream
    verifier_commit_nil = lambda do |commit|
      fail "*** Format du log non conforme a celui attendu" unless commit.nil?
    end

    PRuby::Stream.source( `git --git-dir=#{@depot}/.git log`.split("\n") )
      .fastflow( stateful: true,
                 initial_state: nil,
                 at_eos: verifier_commit_nil ) do |commit, ligne|
      if LIGNE_COMMIT =~ ligne
        verifier_commit_nil.call( commit )
        [Commit.new($1), PRuby::GO_ON]
      elsif /Author:\s*([^<]+)\s+/ =~ ligne
        commit.auteur = $1.strip
        [commit, PRuby::GO_ON]
      elsif /Date:\s+\w{3}\s+(\w{3})\s(\d{1,2})\s(.*)\s(\d{4})\s.\d{4}$/ =~ ligne
        commit.date = Date.parse "#$1 #$2 #$4"
        commit.heure = $3
        [nil, commit]
      else
        [commit, PRuby::GO_ON]
      end
    end
  end

  def commiteurs
    commit_stream
      .map(&:auteur)
      .sort
      .uniq
      .to_a
  end

  def commiteurs
    commit_stream
      .map(&:auteur)
      .sort
      .uniq
      .to_a
  end

  def commits_par_commiteur
    commit_stream
      .group_by(&:auteur)
      .map { |p| [p.first, p.last.count] }
      .sort { |p1, p2| p2.last <=> p1.last }
      .to_a
  end

  def commits_par_date
    commit_stream
      .group_by(&:date)
      .map { |p| [p.first, p.last.count] }
      .sort { |p1, p2| p2.last <=> p1.last }
      .map { |p| [p.first.to_s, p.last] }
      .to_a
  end

  def commits_par_mois
    commit_stream
      .group_by { |c| [c.date.year, c.date.month] }
      .map { |p| [p.first, p.last.count] }
      .sort { |p1, p2| p1.first <=> p2.first }
      .map { |p| "#{p.first.first}/#{p.first.last} => #{p.last}" }
      .to_a
  end
end
