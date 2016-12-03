require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rake/clean'
require 'pp'

VERBOSE = true \
   && false

AVEC_NG_SERVER = true \
   #&& false


##################################################
# Fonction auxiliaire pour simplifier le code.
# Attention: MONKEY PATCHING!!!
class Array
  def to_spec
    map { |x| "#{x}_spec.rb" }
  end
end

##################################################
# WIP
##################################################
task :_WIP do
  #sh %{ruby spec/stream_spec.rb -n /tee/}
  #sh %{ruby spec/stream_spec.rb -n /join/}
  #sh %(yard doc lib)
end

#task :WIP => [:doc]

#task :WIP => ['farm'].to_spec
#task :WIP => ['channel'].to_spec
#task :WIP => ['wrap_around'].to_spec
#task :WIP => ['pipeline', 'pipeline_complexe'].to_spec
#task :WIP => :Pipelines
#task :WIP => [:stream].to_spec



##################################################
# default
##################################################

task :default => ['ng_server', :WIP]

#task :default => [:all]
#task :default => ['ng_server', :test]

##################################################
# VIEUX WIP
##################################################

task :WIP  => :all
task :all => [:test, :Programmes]

task :Distance do
  sh %(rake Programmes[DistanceEdition])
end

task :Pipelines do
  sh %(rake Programmes[Pipelines])
end

task :Divers do
  sh %(rake Programmes[Divers])
end

#task :WIP => [:matrice].to_spec

#task :WIP => [:pcall, :fibo].to_spec
#task :WIP => [:peach].to_spec
#task :WIP => [:preduce].to_spec

#task :WIP => [:preduce_arbre].to_spec

#task :WIP => ['pipeline', 'pipeline_complexe', 'wrap_around'].to_spec

#task :WIP => [:future, :fibo].to_spec
#task :WIP => [:channel].to_spec
#task :WIP => [:details_ruby].to_spec

#task :WIP => [:doc]

##################################################

#task :WIP => [:matrice_bm]
#task :WIP => [:matrices_essais]
#task :WIP => [:threads_forkjoin_essais]
#task :WIP => [:somme_tableaux_pcall_essais]


##################################################
# Diverses taches definies explicitement, pour des programmes
# d'essais, exemples ou benchmarks.
##################################################

task :matrice_bm do
  executer_essais 'matrice_bm'
end

task :somme_tableaux_pcall_essais do
  executer_essais 'somme-tableaux-pcall'
end

task :matrices_essais do
  executer_essais 'matrices'
end

task :threads_forkjoin_essais do
  executer_essais 'sommation-tableau'
  executer_essais 'somme-tableaux'
end

task :hello_essais do
  executer_essais 'hello-seq'
  executer_essais 'hello-thread'
  executer_essais 'hello-pcall'
end


##################################################
# Regles et fonctions auxiliaires.
##################################################

rule /.*_spec\.rb/ do |task|
  /(.*)_spec\.rb/ =~ task.name
  fich = $1
  executer_spec fich
end

def executer_spec( la_spec, verbose = nil )
  verb1, verb2 = '', ''
  gc = '' #<< '-J-verbose:gc'

  verb1, verb2 = '-Ilib:test', '-v' if verbose || VERBOSE


  # Remarque: Sur Linux, pour pipeline_spec, le temps passe du simple
  # au double (13 -> 26) selon qu'on utilise, ou non, ces options!
  lancement_rapide_jruby = '-X-C --dev'

  lancement_rapide_jruby << ' --ng' if AVEC_NG_SERVER

  sh "ruby #{lancement_rapide_jruby} #{verb1} #{gc} spec/#{la_spec}_spec.rb #{verb2}"
end

def executer_essais( le_pgm )
  sh "ruby -X-C --dev essais/#{le_pgm}.rb"
end

##################################################
# Diverses taches definies implicitement.
##################################################

# Les differentes cibles associees a ces taches rake:
#
#   $ rake test
#       => all tests
#   $ rake test TEST=spec/foo_spec.rb
#       => only foo_spec.rb
#   $ rake test ... TESTOPTS='-v'
#       => run in verbose mode (each test name is printed as executed)
#

Rake::TestTask.new do |t|
  t.libs << '.' << 'spec'
  t.test_files = FileList['spec/*spec.rb']
end

#
# Autre possibilite = via spec/spec-helper.rb
#
# $ ruby spec/spec_helper.rb
# $ ruby spec/foo_spec.rb
#


##################################################
# Pour l'execution des tests dans les repertoires
# de Programmes
##################################################

task :Programmes, [:repertoire] do |t, args|
  args.with_defaults(:repertoire => '*')
  rep = args.repertoire

  dirs = Rake::FileList.new( "Programmes/#{rep}" ) do |files|
    files.exclude(/common.rake/)
  end

  dirs.each do |dir|
    sh %(cd #{dir}; rake)
  end
end


##################################################
# Emacs tags
##################################################
desc 'Generer le fichier TAGS, en incluant les spec'
task :tags_with_spec do
  mk_tags
end

desc 'Generer le fichier TAGS, en excluant les spec'
task :tags do
  mk_tags :EXCLUDE_SPEC
end

def mk_tags( exclude_spec = nil )
  exclude_spec = exclude_spec ? '--exclude=spec' : ''

  if ENV['HOST'] == 'MacOS'
    sh %(/usr/local/Cellar/ctags/5.8/bin/ctags -e -R #{exclude_spec} --exclude=doc --exclude=.git -f TAGS)
  else
    sh %(/usr/bin/ctags -e -R #{exclude_spec} --exclude=doc --exclude=.git -f TAGS)
  end
end

##################################################
# Pour generer la documentation
##################################################
desc 'Pour lancer le serveur pour visualisation interactive de la documentation'
task :server_yard do
  sh %(yard server --reload doc lib)
end

task :yard_server => :server_yard
task :doc_server  => :server_yard
task :server_doc  => :server_yard

desc 'Generer la documentation avec yard, de facon locale'
task :doc do
  sh %(yard doc lib)
end

desc 'Generer la documentation avec yard et la mettre sur le site Web pour INF5171'
task :doc_web => :doc do
  sh %(scp -r doc/* tremblay@zeta.labunix.uqam.ca:public_html/INF5171/pruby)
end

task :web_doc => :doc_web

##################################################
# Pour l'execution du server ng
##################################################
file 'ng_server' do
  touch 'ng_server'
  if AVEC_NG_SERVER
    sh %(jruby --ng-server &)
    sleep 0.5 # Pour laisser le temps au serveur de demarrer
  end
end

##################################################
# Creation du gem
##################################################
desc 'Pour construire le gem'
task :gem do
  sh %(gem build pruby.gemspec)
end

file "pruby-#{PRuby::VERSION}.gem" => [:gem]

desc 'Pour installer le gem et le copier sur japet'
task :install_gem => ["pruby-#{PRuby::VERSION}.gem"] do
  # Ca fait le bon appel... mais ca plante!?
  # Je ne vois pas pourquoi!?
  puts "*** Il faut executer localement 'gem install pruby-#{PRuby::VERSION}.gem'"
  sh %(scp pruby-#{PRuby::VERSION}.gem tremblay_gu@malt.labunix.uqam.ca:)
  puts "*** Il faut ensuite aller sur japet: 'rvmsudo gem install pruby-#{PRuby::VERSION}.gem'"
end

##################################################
# Nettoyage
##################################################
CLEAN.include('ng_server')
CLEAN.include('TAGS')
CLEAN.include('pruby-*.gem')

task :clean do
  num = `ps -e |grep 'ware/nailgun' | head -1 | grep -v grep`
  unless num == ''
    puts 'Killing ng-server'
    num =~ /\s*(\d+)\s+/
    pid = $1
    sh %(kill -9 #{pid})
  end
  `~/cmd/effacer-inutiles.sh 2> /dev/null`
end

CLOBBER.include( 'tmp/' )
CLOBBER.include( 'doc/' )
CLOBBER.include( 'pkg/' )
CLOBBER.include( 'Programmes/Image/*-gonfle.ppm' )
CLOBBER.include( 'Programmes/Image/UQAM-ascii.ppm' )
CLOBBER.include( 'Programmes/Image/mandelbrot.ppm' )

desc 'Nettoyer a fond, en supprimant les fichiers inutiles'
task :cleanxtra => [:clobber]


##################################################
# Evaluation de la qualite
##################################################
task :qualite => [:flog, :flay, :reek]

desc 'Analyse statique de metriques de qualite'
task :flog do
  puts '** Appel de flog -- metriques de qualite **'
  sh %(flog --verbose --blame --details  lib/*.rb lib/*/*.rb)
end

desc 'Analyse statique de detection du code DRY'
task :flay do
  puts '** Appel de flay -- detection de code non DRY **'
  sh %(flay --diff lib/*.rb lib/*/*.rb)
end

desc 'Analyse statique de detection de code smells'
task :reek do
  puts '** Appel de reek -- detection de "code smells" **'
  sh %(reek lib/*.rb lib/*/*.rb; echo '' )
end

##################################################
# Couverture de tests avec simplecov
##################################################
task :coverage do
  old_cov = ENV['COVERAGE']
  ENV['COVERAGE'] = 'true'
  Rake::Task['test'].invoke
  Rake::Task['Programmes'].invoke
  ENV['COVERAGE'] = old_cov
end

