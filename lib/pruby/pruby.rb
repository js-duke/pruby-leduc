module PRuby

  # Pour que les exceptions se propagent.
  Thread.abort_on_exception = true

  # Les deux sortes de thread et les methodes associees.
  @methodes_de_thread = {
    :THREAD => :pcall_thread,
    :FORK_JOIN_TASK => :pcall_fj_task
  }

  # Le pool pour les threads forkjoin
  @pool = ForkJoin::Pool.new

  # La sorte de thread par defaut.
  @thread_kind = :THREAD

  # Le nombre de threads par defaut.
  @nb_threads = System::CPU.count

  # Le nombre effectif (+/-) de threads utilises.
  @nb_threads_used = nil

  # Le nombre effectif (+/-) de taches creees.
  @nb_tasks_created = 0

  # Le verrou si on desire calculer de facon exacte le nombre de
  # taches creees, auquel cas il faut faire un acces protege a la
  # variable precedente.
  @mutex_nb_taches = Mutex.new


  class << self
    # Nombre de threads a utiliser par defaut pour l'execution de
    # peach, peach_index, pmap, preduce.
    #
    # @return [Fixnum]
    attr_reader :nb_threads

    # Indique le nombre de threads a utiliser par defaut pour
    # l'execution de peach, peach_index, pmap, preduce.
    #
    # @!parse attr_writer :nb_threads
    # @return [Fixnum]
    #
    def nb_threads=( nb )
      DBC.require nb > 0, "*** Le nombre de threads doit etre superieur a 0"

      @nb_threads = nb
    end

    # Nombre de threads effectivement utilises pour l'execution de
    # peach, peach_index, pmap, preduce.
    #
    # @return [Fixnum]
    attr_reader :nb_threads_used

    # Nombre de taches creees lors de l'execution de pcall, future ou
    # version dynamique de peach, peach_index, pmap ou preduce.
    #
    # @return [Fixnum]
    #
    # @note Le nombre de taches creees n'est pas exacte, a moins qu'un
    #   appel ne soit fait au prealable a la methode
    #   with_exact_nb_tasks.
    #
    #   Justification: Pour avoir le nombre exact de taches, il faut
    #   utiliser un verrou (ou une variable atomique) ce qui ajoute
    #   des conflits d'acces inutiles. Donc, a n'utiliser que de facon
    #   exceptionnelle, car le verrou utilise est un verrou
    #   non-reentrant donc le meme thread peut vouloir l'obtenir a
    #   nouveau, ce qui genere une erreur.
    #
    attr_reader :nb_tasks_created

    # Determine si le decompte du nombre de taches est fait de facon
    # exacte ou non. Voir {PRuby.nb_tasks_created}.
    #
    # @!parse attr_reader :with_exact_nb_tasks?
    # @return [Bool]
    #
    def with_exact_nb_tasks?
      @with_exact_nb_tasks
    end

    # Assure que le decompte du nombre de tache soit fait de facon
    # exacte. Voir {PRuby.nb_tasks_created}.
    #
    # @!parse attr_writer :with_exact_nb_tasks
    # @return [Bool]
    #
    def with_exact_nb_tasks=( b )
      @with_exact_nb_tasks = b
    end

    # Indique la sorte de threads desire pour l'execution d'un pcall. Si
    # :THREAD alors ce sont des Thread JRuby. Si :FORK_JOIN_TASK alors
    # ce sont des threads encore plus legers de la bibliotheque
    # forkjoin.
    #
    # @!parse attr_writer :thread_kind
    # @return [:THREAD, :FORK_JOIN_TASK]
    #
    def thread_kind=( sorte )
      DBC.check_value( sorte, @methodes_de_thread.keys )

      @thread_kind = sorte
    end

    # Retourne l'index du thread lorsque ce thread a ete cree dans un
    # peach/peach_index/pmap/preduce.
    #
    # @require L'appel se fait a partir d'un thread cree pour un
    #   peach, peach_index, pmap ou preduce.
    #
    # @return [Fixnum]
    # @ensure 0 <= thread_index < nb_threads_used
    #
    def thread_index
      Thread.current[:thread_index]
    end
  end

  # Effectue un appel parallele a une serie de lambdas. On peut
  # specifier soit uniquement des Proc (lambdas), soit un ou plusieurs
  # Range suivi d'un Proc.  Si un Range est present, alors on va creer
  # autant de threads que d'elements dans le Range et chaque Proc
  # recevra en argument l'element du Range.
  #
  # @param [liste de Range ou Proc] args Liste des lambdas a executer avec ou sans Range indiquant les instances a creer
  # @return [void]
  # @require args.size > 1
  # @require Si un Range est present, alors il doit etre immediatement suivi d'un Proc qui recoit un argument
  # @require Si un Range suivi d'un Proc est present, alors il ne doit pas avoir ete precede d'un Proc sans Range
  #
  # @example
  #  PRuby.pcall lambda { puts "foo" }, lambda { puts "bar" }, lambda { puts "baz" }
  #  PRuby.pcall (1..10), lambda { |i| puts i }
  #  PRuby.pcall (1..10), lambda { |i| puts i+1 }, (0..100), lambda { |i| puts 100*i }, lambda { puts "foo" }
  #
  def self.pcall( *args )
    # On permet des Range, mais seulement au debut:
    #   pcall [Range, Proc,]* Proc*

    DBC::assert args.size > 1, "*** Un appel a pcall devrait contenir au moins deux elements, sinon aucun interet!"

    thread_kind = @thread_kind
    if args[0].class == Symbol
      DBC.check_value( args[0], @methodes_de_thread.keys )
      thread_kind = args.shift
      DBC::assert args.size > 1, "*** Un appel a pcall devrait contenir au moins deux elements, sinon aucun interet!"
    end

    while args[0].class == Range
      range = args.shift
      le_lambda = args.shift
      DBC.require le_lambda.arity == 1, "*** Le lambda qui suit un range dans un pcall doit recevoir un argument"
      args.push( *generate_lambdas( range, le_lambda ) )
    end

    DBC.require args.all? { |a| a.class == Proc }, "*** Tous les autres arguments de pcall doivent etre des Procs (lambdas)"
    method = @methodes_de_thread[thread_kind]
    send method, *args
  end

  #
  # Cree un future a partir d'une expression a evaluer, representee
  # soit par un argument explicite de type Proc (lambda), soit par un
  # bloc.
  #
  # @param [Proc,nil] expr L'expression a evaluer
  # @param [:FORK_JOIN_TASK, :THREAD] sorte_de_thread La sorte de thread a creer
  # @param block Un bloc representant l'expression a evaluer
  # @return [PRubyFuture] Un future sur lequel on pourra faire un value
  #    pour obtenir la valeur resultante (appel a value qui sera bloquant)
  # @require Soit un lambda est fourni en argument, soit un bloc mais pas les deux
  #
  def self.future( expr = nil, sorte_de_thread = :THREAD, &block )
    DBC.require expr.nil? != !block_given?, "*** Dans future, il faut fournir soit un bloc, soit un lambda"
    DBC.require( expr.class == Proc, "*** L'argument fourni au future doit etre un Proc" ) if expr

    incr_nb_tasks_created 1

    case sorte_de_thread
    when :FORK_JOIN_TASK
      @pool.submit PRubyFuture.new( expr || block )
    when :THREAD
      if block_given?
        Thread.new( &block )
      else
        Thread.new { expr.call }
      end
    else
      DBC.check_value( sorte_de_thread, @methods_de_thread.keys,
                       "*** sorte_de_thread invalide" )
    end
  end


  #
  # Cree une source pour un pipeline. Simple operation de facade.
  #
  # @param (see PipelineFactory.source)
  # @return (see PipelineFactory.source)
  # @ensure (see PipelineFactory.source)
  #
  def self.pipeline_source( source, source_kind = nil )
    PipelineFactory.source source, source_kind
  end


  #
  # Cree un pipeline. Simple operation de facade.
  #
  # @param (see PipelineFactory.pipeline)
  # @return (see PipelineFactory.pipeline)
  # @ensure (see PipelineFactory.pipeline)
  #
  def self.pipeline( *args )
    PipelineFactory.pipeline *args
  end

  #
  # Cree un puits pour un pipeline. Simple operation de facade.
  #
  # @param (see PipelineFactory.sink)
  # @return (see PipelineFactory.sink)
  # @ensure (see PipelineFactory.sink)
  #
  def self.pipeline_sink( sink )
    PipelineFactory.sink sink
  end


  private

  # Genere une serie de lambdas, un par element du range, qui recevra
  # l'element du range et appelera le lambda avec cet element.
  #
  def self.generate_lambdas( range, le_lambda )
    range.map { |i| lambda { le_lambda.call(i) } }
  end

  # Mise en oeuvre finale de pcall avec des threads forkjoin.
  #
  def self.pcall_fj_task( *args )
    PRuby.nb_threads_used = @pool.parallelism
    incr_nb_tasks_created args.size
    @pool.
      invoke_all(args)
  end

  # Mise en oeuvre finale de pcall avec des "vrais" threads.
  #
  def self.pcall_thread( *args )
    PRuby.nb_threads_used = args.size
    threads = Array.new( args.size )
    args.each_index do |k|
      threads[k] = Thread.new &args[k]
    end
    threads.each do |t|
      t.join
    end
  end


  # Setter pour mettre a jour le nombre de threads utilises.
  #
  def self.nb_threads_used=( nb )
    @nb_threads_used = nb
  end


  # Incremente le nombre de taches creees, de facon atomique ou non...
  #
  def self.incr_nb_tasks_created( nb )
    @mutex_nb_taches.lock if with_exact_nb_tasks?
    @nb_tasks_created += nb
    @mutex_nb_taches.unlock if with_exact_nb_tasks?
  end
end
