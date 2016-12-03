module PRuby

  ############################################################
  #
  # Definition des methodes paralleles qui s'appliquent
  # directement (et uniquement) a des Array ou des Range.
  #
  # Les methodes publiques sont les suivantes:
  # - peach
  # - peach_index
  # - pmap
  # - preduce
  #
  # Ces methodes sont definies dans le present module, mais ensuite
  # les classes Array et Range sont etendues avec ces methodes (vie
  # des includes).
  #
  ############################################################

  module PArrayRange

    # Execute un bloc de code sur chacun des elements d'un Array ou Range
    #
    # @option opts [Fixnum] :nb_threads Le nombre de threads avec lesquels on desire que le traitement soit fait
    # @option opts [Bool] :static si true alors repartition uniforme par tranches d'elements adjacents
    # @option opts [Fixnum] :static Distribution cyclique en groupe de :static elements
    # @option opts [Bool] :dynamic si true alors dynamique avec taille de tache = 1
    # @option opts [Fixnum] :dynamic Distribution dynamique avec taille de tache = :dynamic
    # @param b Le bloc a executer
    # @return [self,self.to_a] Le tableau initial ou un tableau obtenu du Range (avec to_a)
    # @note Par defaut, si aucune option n'est specifiee, ceci est equivalent a utiliser
    #      PRuby.nb_threads threads avec un mode :static true. Donc: "pfoo()" = "pfoo( nb_threads: PRuby.nb_threads, static: true )" (pour pfoo = peach, peach_index, pmap, preduce).
    # @example
    #   a = [10, 20, 30]
    #   b = Array.new(3)
    #   r = a.peach { |x| b[x / 10 - 1] = x + 1 }
    #   a == [10, 20, 30]
    #   r.equal? a
    #   b == [11, 21, 31]
    #
    def peach( opts = {}, &b )
      return to_a.peach( opts, &b ) if self.class == Range

      pforall( self, false, opts, &b )
    end

    # Execute un bloc de code sur chacun des indices d'un Array
    #
    # @require self.class != Range
    # @option (see #peach)
    # @param b Le bloc a executer
    # @return [self] Le tableau initial ou un tableau obtenu du Range (avec to_a)
    # @note (see #peach)
    # @example
    #   a = [10, 20, 30]
    #   b = Array.new(3)
    #   r = a.peach_index { |k| b[k] = k + 1 }
    #   a == [10, 20, 30]
    #   r.equal? a
    #   b == [1, 2, 3]
    #
    def peach_index( opts = {}, &b )
      DBC.require( self.class != Range,
                   "*** La methode peach_index ne peut pas etre utilisee avec un Range" )

      pforall( self, true, opts, &b )
    end

    # Applique un bloc de code sur chacun des elements d'un Array ou
    # Range pour produire un nouvel Array avec les resultats
    #
    # @option (see #peach)
    # @param b Le bloc a executer
    # @return [Array] Un nouveau tableau contenant le resultat de l'application du bloc sur chacun des elements du tableau ou range initial
    # @note (see #peach)
    # @example
    #   a = [10, 20, 30]
    #   r = a.pmap { |x| x+1 }
    #   a == [10, 20, 30]
    #   r == [11, 21, 31]
    #
    def pmap( opts = {}, &b )
      return to_a.pmap( opts, &b ) if self.class == Range

      pforall( Array.new(size), false, opts, &b )
    end

    # Applique un bloc, qui devrait avoir deux arguments et etre
    # associatif, pour produire la reduction des elements d'un Array
    # ou d'un Range.
    #
    # @param val_initiale Valeur initiale a utiliser, qui devrait
    #      etre l'element neutre si l'operation est cumulative (+, *, etc.)
    # @option opts [Fixnum] :nb_threads Le nombre de threads avec lesquels on desire que le traitement soit fait
    # @option opts [Symbol, Proc] :final_reduce L'operateur binaire a utiliser
    #         pour la reduction finale des resultats intermediaires
    #         (generalement associatif)
    # @param b Le bloc de code a executer sur chacun des elements d'une tranche
    # @return [T, Fixnum] La valeur finale reduite. Si self.class == Array<T> alors return.class == T sinon return.class = Fixnum
    # @require Le bloc recoit deux arguments... et devrait etre associatif
    # @require La fonction final_reduce recoit deux arguments... et devrait etre associative
    # @example
    #   a = [10, 20, 30]
    #   r = a.preduce(0) { |x, y| x+y }
    #   r == 60
    #   a == [10, 20, 30]
    #
    #   r = a.preduce(23) { |x, y| [x, y].max }
    #   r == 30
    #   r = a.preduce(99) { |x, y| [x, y].max }
    #   r == 99
    #
    #   a = [11, 2, 30, 40, 40, 39, 38, 5, 6]
    #   r = a.preduce(0, nb_threads: 3, final_reduce: :+) do |m, x|
    #     [m, x].max
    #   end
    #   r == 30 + 40 + 38
    #
    # @note Utilise toujours une repartition statique par tranche
    #   d'elements adjacents!  Raison: pcq. trop complique de faire
    #   autrement... mais surtout pas necessaire, car il n'y a pas (il
    #   ne devrait pas y avoir!?)  vraiment de difference dans le temps
    #   d'execution entre les taches!
    #
    # @note La valeur initiale est utilisee... par chacun des threads!
    #   Ceci implique que si cette valeur n'est pas un element neutre
    #   de l'operation binaire, alors le resultat final dependra du
    #   nombre de threads utilises.  Donc, il est preferable
    #   d'utiliser un element neutre.
    #
    def preduce( val_initiale, opts = {}, &b )
      return to_a.preduce( val_initiale, opts, &b ) if self.class == Range

      return val_initiale if size == 0

      nb_threads = nombre_de_threads( opts[:nb_threads], size )
      resultat = (0...nb_threads).map { val_initiale }
      fork_and_wait_threads_adj( nb_threads, nil, true ) do |i|
        resultat[PRuby.thread_index] = yield( resultat[PRuby.thread_index], self[i] )
      end

      # La reduction finale peut devoir etre faite de facon differente.
      b = opts[:final_reduce] if opts[:final_reduce]
      resultat.reduce(&b)
    end

    # @!visibility private
    # Determine les bornes (inferieure et superieure) d'une tranche d'elements
    # adjacents,
    #
    # @param [Fixnum] k Indice de la tranche
    # @param [Fixnum] n Nombre d'elements a repartir
    # @param [Fixnum] nb_threads Nombre de threads entre lesquels repartir les elements
    # @return [Array<Fixnum, Fixnum>] Bornes inferieure et superieure (inclusives) de la tranche
    #
    # @note Definie comme methode publique uniquement pour les tests.
    #
    def bornes_de_tranche( k, n, nb_threads )
      nb_min_par_thread = n / nb_threads
      nb_a_distribuer = n % nb_threads

      b_inf = k * nb_min_par_thread + [k, nb_a_distribuer].min
      b_sup = (k+1) * nb_min_par_thread + [k+1, nb_a_distribuer].min - 1
      [b_inf, b_sup]
    end


    private

    def analyser_arguments( resultat, opts )
      nb_threads = nombre_de_threads( opts[:nb_threads], size )
      tt_statique, tt_dynamique = opts[:static], opts[:dynamic]
      resultat = (resultat.eql? self) ? nil : resultat
      DBC.require( tt_statique.nil? || tt_dynamique.nil?,
                   "*** On ne peut pas specifier a la fois statique et dynamique" )

      method = nil
      if tt_dynamique
        tt_dynamique = 1 if tt_dynamique == true
        DBC.require( tt_dynamique > 0,
                     "*** La taille des taches doit etre un entier superieure a 0" )
        method = :fork_and_wait_threads_dynamique
        opts = [tt_dynamique, nb_threads, resultat]
      else
        adjacent = true # Jusqu'a preuve du contraire, donc y compris si "static: true" ou pas defini
        if tt_statique && tt_statique != true
          DBC.require( tt_statique.class == Fixnum && tt_statique > 0,
                       "*** La taille des taches doit etre un entier superieur a 0" )
          adjacent = nb_threads * tt_statique > size
        end
        if adjacent
          method = :fork_and_wait_threads_adj
          opts = [nb_threads, resultat]
        else
          method = :fork_and_wait_threads_cyclique
          opts = [tt_statique, nb_threads, resultat]
        end
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

    def fork_and_wait_threads_adj( nb_threads, resultat = nil, sur_index = nil )
      PRuby.nb_threads_used = nb_threads

      threads = (0...nb_threads).map do |k|
        b_inf, b_sup = bornes_de_tranche( k, size, nb_threads )
        Thread.new(b_inf, b_sup) do |inf, sup|
          Thread.current[:thread_index] = k
          (inf..sup).each do |i|
            r = yield (sur_index ? i : self[i])
            resultat[i] = r if resultat
            r
          end
        end
      end
      threads.map(&:join)
    end

    def fork_and_wait_threads_dynamique( taille_tache, nb_threads, resultat = nil, sur_index = nil )
      pool = ForkJoin::Pool.new nb_threads
      PRuby.nb_threads_used = pool.parallelism

      tasks = (0...size).step(taille_tache).map do |k|
        PRubyArraySliceTask.new( self, k, [size, k+taille_tache].min-1 ) do |i|
          r = yield (sur_index ? i : self[i])
          resultat[i] = r if resultat
          r
        end
      end

      PRuby.incr_nb_tasks_created size
      pool.invoke_all( tasks )
    end

    def fork_and_wait_threads_cyclique( taille_tache, nb_threads, resultat = nil, sur_index = nil )
      PRuby.nb_threads_used = nb_threads

      threads = (0...nb_threads).map do |k|
        Thread.new(k, taille_tache, nb_threads, size) do |k, tt, nb_threads, n|
          step = nb_threads * tt

          (k*tt..n).step(step).each do |bloc|
            # On traite un bloc (tache) d'au plus tt (taille_tache)
            (bloc...[bloc+tt,n].min).each do |j|
              r = yield (sur_index ? j : self[j])
              resultat[j] = r if resultat
              r
            end
          end
        end
      end
      threads.map(&:join)
    end

    def nombre_de_threads( nb_threads, n )
      DBC.require( nb_threads.nil? || nb_threads > 0,
                   "*** Le nombre de threads specifie doit etre superieur a 0" )

      nb_threads ||= PRuby.nb_threads

      [nb_threads, n].min
    end
  end

  # On etend les modules Array et Range avec les methodes ainsi definies.
  Array.send(:include, PRuby::PArrayRange)
  Range.send(:include, PRuby::PArrayRange)


  # @!visibility private
  # Class auxiliaire, privee, utilisee pour les ForkJoin::Task de la
  # bibliotheque jruby/Java.
  class PRubyArraySliceTask < ForkJoin::Task
    def initialize( a, i, j, &block )
      @a, @i, @j, @block = a, i, j, block
    end

    def call
      (@i..@j).each do |k|
        @a.instance_exec(k, &@block)
      end
    end
  end
end
