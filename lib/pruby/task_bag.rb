module PRuby

  #
  # Classe pour un sac dynamique de taches -- donc dans lequel on peut
  # retirer mais aussi ajouter des taches de facon dynamique, i.e., en
  # cours d'execution.
  #
  # @note Il s'agit (pour l'instant?) d'une mise en oeuvre naive, car
  #    elle utilise un Channel pour le sac (la queue/file) des
  #    taches... Il y a donc deux niveaux de verrous :( Toutefois, le
  #    verrou de TaskBag est crucial pour que cela fonctionne
  #    correctement: l'utilisation de Channel est uniquement une facon
  #    simple de signaler qu'il n'y aura plus rien comme taches en
  #    utilisant EOS.
  #
  class TaskBag

    DEBUG = true && false

    # Cree un nouveau sac de taches.
    #
    # @param nb_threads Le nombre de threads qui pourraient bloquer (via
    #    un get) sur ce sac de taches.
    #
    # @note Plus precisement, nb_threads indique combien de threads vont
    #   faire des get sur le sac.  C'est ce nombre qui permet de
    #   detecter la terminaison: quand nb_threads-1 threads sont bloques
    #   sur le get et que le dernier thread fait un get, alors tous les
    #   threads sont reactives avec la valeur nil comme resultat du get.
    #   Si le nombre de threads qui obtiennent des valeurs du sac est
    #   different de nb_threads, alors le comportement quant a la
    #   terminaison pourrait etre incorrect.
    #
    def initialize( nb_threads )
      @nb_threads = nb_threads
      @nb_threads_en_attente = 0
      @mutex = Mutex.new
      @cond = ConditionVariable.new
      @attente_fin = ConditionVariable.new
      @queue = PRuby::Channel.new
      @termine = false
      @nb_termines = 0
    end

    #
    # Lance l'execution d'un groupe de threads qui vont se partager un
    # sac de taches, sac qu'ils utiliseront par l'intermediaire
    # d'appels each et, s'ils generent de nouvelles taches, par des
    # appels a put.
    #
    # Exemple typiques d'utilisation -- execute avec 4 threads et avec
    # comme taches initiales t1, t2, ..., tk:
    #
    # resultats = TaskBag.run( 4, t1, t2, ..., tk ) do |tb|
    #   ...
    #   tb.each do |task|
    #      traiter task
    #   end
    #   resultat_a_retourner
    # end
    #
    # @param [Fixnum] nb_threads nombre de threads a lancer
    # @param [Array<Object>] tasks les taches a mettre dans le sac *avant* de lancer les threads
    # @return [Array<Object>] la liste des resultats retournes par chacun des threads
    #
    # @yieldparam [TaskBag] tb le sac de taches partage par les threads
    # @yieldparam [Fixnum] k le numero du thread
    # @yieldreturn [Object] le resultat produit a la fin par le thread
    #
    # @require le bloc utilise each pour obtenir les taches qu'il
    #    devra traiter et n'utilise pas get -- mais peut utiliser put
    #    pour ajouter des nouvelles taches, identifiees en cours de traitement
    # @ensure return.size == nb_threads
    #
    def self.create_and_run( nb_threads, *tasks )
      DBC.require !tasks.empty?, "*** Dans run/create_and_run: Il faut specifier au moins une tache"

      # On cree le sac de taches avec ses taches initiales.
      tb = new( nb_threads )
      tasks.each do |task|
        tb.put task
      end

      # On lance les threads, on attend qu'ils terminent et on
      # retourne leurs resultats.
      (0...nb_threads)
        .map { |k|  PRuby.future { yield tb, k } }
        .map(&:value)
    end

    class << self
      alias_method :run, :create_and_run
    end

    # Ajoute une tache dans le sac de taches. Ne bloque jamais (sac de
    #   taille non bornee.)
    #
    # @param task La tache a ajouter
    # @return [self]
    # @ensure La tache a ete ajoutee dans le sac
    #
    def put( task )

      @mutex.synchronize do
        puts "TaskBag#put( #{task} )" if DEBUG
        @queue.put( task )
        @cond.broadcast
      end

      self
    end

    # Lance une exception si on est en train de faire un each
    # sinon fait le get
    def fail_get
      fail("*** Lorsque each est utilise, il ne faut pas faire d'appel a get")
    end

    # Retire une tache du sac de taches. Bloque si le sac est
    #   actuellement vide mais que d'autres taches pourraient etre
    #   ajoutees parce que des threads sont encore actifs.
    #
    # @return [nil, Object] La tache obtenue, ou bien nil
    #   lorsqu'il n'y a plus de taches... et qu'il ne pourra plus y en
    #   avoir (tous les nb_threads threads sont en attente d'une tache).
    #
    def private_get
      task = nil
      @mutex.synchronize do
        loop do
          unless @queue.empty?
            # Il y a une tache disponible.
            task = @queue.get
            puts "Il y a une tache disponible: task = #{task.inspect}" if DEBUG
            if task == EOS
              # EOS => privee a mise en oeuvre.
              task = nil
              @nb_termines += 1
            end
            break
          end

          puts "Pas de tache" if DEBUG
          if @nb_threads_en_attente == @nb_threads - 1
            puts "... et dernier thread actif!!" if DEBUG
            # Dernier thread actif: on signale aux autres threads
            # qu'il n'y aura plus rien.
            @queue.put EOS
            @termine = true
            @cond.broadcast
          else
            puts "... mais d'autres threads encore actifs!!" if DEBUG
            # D'autres threads sont encore actifs et pourraient
            # ajouter des taches: on bloque.
            @nb_threads_en_attente += 1
            @cond.wait( @mutex )
            @nb_threads_en_attente -= 1
          end
        end
      end

      puts "TaskBag#get => #{task}" if DEBUG
      @attente_fin.signal if @nb_termines == @nb_threads
      task
    end


    # Itere sur des elements du sac de taches.
    #
    # Plus precisement, les elements du sac sont repartis entre les
    # divers threads qui utilisent le sac, et donc un thread donne
    # n'obtient qu'un sous-ensemble des elements mis dans le sac.
    #
    # Si un thread utilise each, *il ne doit pas utilise get*.  Par
    # contre, il peut utiliser put pour ajouter un tache dans le sac.
    #
    # Le each se termine lorsque tous les threads qui utilisent le sac
    # de taches sont bloques en attente d'une tache.
    #
    # @yieldparam [Object] une tache a traiter
    # @yieldreturn [void]
    #
    # @return [void]
    #
    # @require aucun appel a get n'est effectue sur le sac!
    #
    def each
      define_singleton_method(:get) { fail_get }
      while task = private_get
        yield( task )
      end  
      define_singleton_method(:get) { private_get }
    end

    # Attente jusqu'a ce que le sac soit devenu inactif parce que vide
    #   et que tous les threads qui l'utilisaient sont devenus inactifs
    #   (i.e., bloques en attente d'une nouvelle tache).
    #
    # @return [void]
    # @ensure done?
    #
    def wait_done
      @mutex.synchronize do
        @attente_fin.wait( @mutex ) while !@termine
      end
    end

    # Indique si le sac est devenu inactif parce que vide et que tous
    #   les threads qui l'utilisaient sont devenus inactifs -- i.e.,
    #   bloques en attente d'une nouvelle tache.
    #
    # @return [Bool]
    #
    def done?
      @termine
    end
    
    alias_method :get, :private_get
  end

  TaskPool = TaskBag
  
end
