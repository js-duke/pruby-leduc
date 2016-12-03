require 'rake/testtask'
require 'rake/clean'

def mk_name( fich, kind )
  "#{fich}_#{kind}.rb"
end

def _default( fich, kind )
end

def default( fich, kind )
  task :default => [mk_name(fich, kind)]

  task mk_name(fich, kind) do
    sh "ruby -X-C --dev #{mk_name(fich, kind)}"
  end
end

def default_ng( fich, kind )
  task :default => [mk_name(fich, kind)]

  task mk_name(fich, kind) do
    sh "ruby -X-C --dev --ng #{mk_name(fich, kind)}"
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
# Nettoyage
##################################################
desc 'Nettoyer a fond, en supprimant les fichiers inutiles'
task :cleanxtra => [:clean] do
  remove_dir( 'tmp', true )
  `rm -f TAGS`
  `~/cmd/effacer-inutiles.sh 2> /dev/null`
  remove_dir( 'doc', true )
end
