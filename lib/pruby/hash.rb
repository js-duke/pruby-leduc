require 'jruby/synchronized'

module PRuby

  class ConcurrentHash < ::Hash
      include JRuby::Synchronized
  end

  module PHash

    # Execute un bloc de code sur chacun des paires d'un Hash
    #
    # @option opts [Fixnum] :nb_threads Le nombre de threads avec lesquels on desire que le traitement soit fait
    # @option opts [Fixnum] :static Distribution cyclique en groupe de :static elements
    # @option opts [Bool] :dynamic si true alors dynamique avec taille de tache = 1
    # @option opts [Fixnum] :dynamic Distribution dynamique avec taille de tache = :dynamic
    # @param b Le bloc a executer
    # @return self Le Hash initial
    def peach( opts = {}, &b )
      pforall( self, false, opts, &b )
    end

    # Execute un bloc de code sur chacun des keys d'un Hash
    #
    # @require self.class != Range
    # @option (see #peach)
    # @param b Le bloc a executer
    # @return self Le Hash initial
    # @note (see #peach)
    def peach_key( opts = {}, &b )
      pforall( self, true, opts, &b )
    end

    # Applique un bloc de code sur chacun des paires d'un Hash 
    # pour produire un nouveau Hash avec les resultats
    #
    # @option (see #peach)
    # @param b Le bloc a executer
    # @return [Array] Un nouveau tableau contenant le resultat de l'application du bloc sur chacun des elements du tableau ou range initial
    # @note (see #peach)
    def pmap( opts = {}, &b )
      pforall( ConcurrentHash.new, false, opts, &b )
    end

    def collect_tranche(taille_tache)
      result = Array.new
      task = Array.new

      self.each do |k, v|
        task.push [k, v]
        if task.size >= taille_tache
          result.push(yield task) 
          task = Array.new
        end
      end

      result.push(yield task) if task.size > 0
      result
    end

    def cyclic_each(taille_tache, nb_cyclic, index)
      step_initial = index * taille_tache
      return nil if step_initial > size # rien a iterer

      step = (nb_cyclic - 1) * taille_tache
      enumerator = self.each
      step_initial.times { enumerator.next }
      loop do
        taille_tache.times { yield enumerator.next }
        step.times { enumerator.next }
      end
    end
    
private

    def analyser_arguments( resultat, opts )
      nb_threads = nombre_de_threads( opts[:nb_threads], size )
      tt_statique, tt_dynamique = opts[:static], opts[:dynamic]
      resultat = (resultat.eql? self) ? nil : resultat
      DBC.require( tt_statique.nil? || tt_dynamique.nil?, "*** On ne peut pas specifier a la fois statique et dynamique" )

      method = nil
      if tt_dynamique
        tt_dynamique = 1 if tt_dynamique == true
        DBC.require( tt_dynamique > 0, "*** La taille des taches doit etre un entier superieure a 0" )
        method = :fork_and_wait_threads_dynamique
        opts = [tt_dynamique, nb_threads, resultat]
      else
        if tt_statique && tt_statique != true
          DBC.require( tt_statique.class == Fixnum && tt_statique > 0, "*** La taille des taches doit etre un entier superieur a 0" )
        else
          tt_statique = 1
        end
        method = :fork_and_wait_threads_cyclique
        opts = [tt_statique, nb_threads, resultat]
      end
      [method, opts]
    end

    # Itere un bloc, en parallele, sur les differents elements d'un tableau.
    #
    # @option (see #peach)
    # @param [Array] resultat Dans quel tableau doivent etre conserves les elements du resultat
    # @param [Bool] sur_index true si on applique le bloc sur les index, false si on applique sur les elements
    # @param b Le bloc a executer
    #
    # @return Le tableau initial si resultat.eql? self, sinon un autre tableau: voir les methodes publiques
    #
    # @raise [DBC::Failure] Divers conditions selon les options
    #
    def pforall( resultat, sur_index, opts = {}, &b )
      return resultat if size == 0

      method, opts = analyser_arguments( resultat, opts )

      # On applique maintenant la methode d'iteration approprie a
      # chacun des elements de l'Array, en yieldant au bloc recu en
      # argument.
      send method, *opts, sur_index, &b

      resultat
    end

    def fork_and_wait_threads_dynamique( taille_tache, nb_threads, resultat = nil, sur_index = nil )
      pool = ForkJoin::Pool.new nb_threads
      PRuby.nb_threads_used = pool.parallelism

      tasks = self.collect_tranche(taille_tache) do |pairs|
        PRubyHashSliceTask.new(self, pairs) do |pair|
          if sur_index
            r = yield pair[0]
          else
            r = yield pair[0], pair[1]         
          end
          resultat[pair[0]] = r if resultat
          r
        end
      end

      PRuby.incr_nb_tasks_created tasks.size
      pool.invoke_all( tasks )
    end

    def fork_and_wait_threads_cyclique( taille_tache, nb_threads, resultat = nil, sur_index = nil )
      PRuby.nb_threads_used = nb_threads

      threads = (0...nb_threads).map do |k|
        Thread.new(k, taille_tache, nb_threads) do |k, tt, nb_threads|
          self.cyclic_each(tt, nb_threads, k) do |key, value|  
            if sur_index
              r = yield key
            else
              r = yield key, value
            end
            resultat[key] = r if resultat
            r
          end
        end
      end
      threads.map(&:join)
    end

    def nombre_de_threads( nb_threads, n )
      DBC.require( nb_threads.nil? || nb_threads > 0, "*** Le nombre de threads specifie doit etre superieur a 0" )

      nb_threads ||= PRuby.nb_threads

      [nb_threads, n].min
    end
  end

  Hash.send(:include, PRuby::PHash)

  # @!visibility private
  # Class auxiliaire, privee, utilisee pour les ForkJoin::Task de la
  # bibliotheque jruby/Java.
  class PRubyHashSliceTask < ForkJoin::Task
    def initialize( hash, pairs, &block )
      @hash, @pairs, @block = hash, pairs, block
    end

    def call
      @pairs.each do |pair|
        @hash.instance_exec(pair, &@block)
      end
    end
  end

end
