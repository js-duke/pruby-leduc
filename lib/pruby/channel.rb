module PRuby

  EOS = :PRUBY_EOS

  #
  # Canal de communication entre les threads faisant partie d'un
  # pipeline. A un canal est associe une file FIFO d'elements: on
  # ajoute en queue avec put et on retire de la tete avec get.
  #
  # Pour simplifier, on dit que le canal contient des elements, plutot
  # que de dire que la queue associee au canal contient des elements.
  #
  class Channel
    include Enumerable

    # @!visibility private
    include Debug

    # @!visibility private
    def _debug_(msg) __debug__(msg, 1); end

    # Constructeur de base.
    #
    # @param [String] name Le nom du canal, utilise essentiellement pour le debogage
    # @param [Fixnum] max_size Taille maximum du canal, i.e., nombre max. d'elements pouvant etre en attente dans le canal. Si max_size == 0, alors canal non-borne
    # @param [Array] contents Contenu initial du canal
    #
    def initialize( name = nil, max_size = 0, contents = [], ignore_nil = nil )
      @name = name || Channel.next_id
      @max_size = max_size
      @contents = contents
      @ignore_nil = !!ignore_nil

      @nb_writers = 1
      @nb_eos_received = 0
      @eos = false
      @mutex = Mutex.new
      @not_empty = ConditionVariable.new
      @not_full = ConditionVariable.new
    end

    # Indique qu'un canal devra recevoir des messages de la part de
    # plusieurs threads.  Pour que le canal propage le EOS aux
    # lecteurs, on devra donc avoir recu plusieurs EOS, i.e., autant
    # de EOS que de threads qui ecrivent.
    #
    # @require nb >= 2
    # @param [Fixnum] nb Nombre de threads qui vont ecrire dans le canal
    # @return [self]
    #
    def with_multiple_writers( nb )
      DBC.require nb >= 2, "*** Dans accept_multiple_eos: nb = #{nb} doit etre >= 2"

      @nb_writers = nb
      self
    end

    # Determine si la fin du flux a ete rencontree. Une fois que true
    # a ete retourne, tous les appels subsequents vont aussi retourner
    # true.
    #
    # @return [Bool]
    #
    def eos?
      @eos
    end

    # Determine si tous les appels requis a close ont ete effectues --
    # en fonction du nombre de writers indiques et du nombre de close
    # effectues.
    #
    # @return [Bool]
    #
    def closed?
      @nb_eos_received == @nb_writers
    end

    # Determine si le canal est presentement vide. Meme si
    # presentement vide, il peut, plus tard, ne plus etre vide si un
    # thread ecrit dans le canal.
    #
    # @return [Bool]
    #
    def empty?
      would_return_something = eos? || !@contents.empty?
      !would_return_something
    end

    # Determine si le canal est presentement plein. Meme si
    # presentement plein, il peut, plus tard, ne plus etre plein si un
    # thread fait un get.
    #
    # @return [Bool]
    #
    def full?
      @max_size > 0 && @contents.size >= @max_size
    end

    # Indique si l'ecriture de nil est permis sur le canal.
    #
    # @return [Bool]
    #
    def ignore_nil?
      @ignore_nil
    end

    # Retourne une chaine representant le canal.
    #
    # @return [String]
    #
    def to_s
      @name.to_s + ":: (#{@contents.size} /" + (@max_size > 0 ? "#@max_size)" : ")")
    end

    # Ajoute un element a la queue du canal.
    #
    # @require (ignore_nil? || !elem.nil?) && !closed?
    # @param elem L'element a ajouter
    # @return [self]
    #
    def put( elem )
      @mutex.synchronize do
        DBC.require( ignore_nil? || !elem.nil?,
                     "*** Cannot put nil into a channel unless explicitly allowed" )
        DBC.require( !closed? || elem == EOS,
                     "*** Cannot put '#{elem}' on a closed channel" )

        _debug_ "#{self}#put( #{elem} )"

        if elem == EOS
          @nb_eos_received += 1
          if @nb_eos_received < @nb_writers
            elem = nil  # Pas le dernier EOS, donc on ne l'ecrit pas!
          end
          @not_full.signal
        else
          @not_full.wait(@mutex) while full?
        end

        _debug_ "#{self}#put( #{elem} ) => #{elem.inspect}"

        if elem
          @contents.push elem
          @not_empty.signal
        end
      end

      self
    end

    alias :<< :put
    alias :emit :put

    # Obtient l'element en tete du canal.
    #
    # @return L'element qui etait en tete du canal. Bloque si empty?
    # @ensure L'element retourne est retire du canal, donc le canal a un element de moins
    #
    def get
      (_debug_ "#{self}#get => EOS"; return EOS) if eos?

      _debug_ "#{self}#get => ..."

      elem = nil
      @mutex.synchronize do
        # INTERESSANT: que se passe-t'il si on remplace while par if?
        # Reponse: condition de course possible liee a discipline "signaler et continuer"!!
        @not_empty.wait(@mutex) while empty?

        elem = eos? ? EOS : @contents.shift

        _debug_ "#{self}#get => ... #{elem}"

        if elem == EOS
          @eos = true
          @not_empty.signal
        end
        @not_full.signal
      end

      elem
    end

    # Lit l'element en tete du canal, mais sans le retirer du canal.
    #
    # @return L'element en tete du canal. Bloque si empty?
    # @ensure Aucun effe sur le contenu du canal
    #
    def peek
      (_debug_ "#{self}#peek => EOS"; return EOS) if eos?

      _debug_ "#{self}#peek => ..."

      elem = nil
      @mutex.synchronize do
        # INTERESSANT: que se passe-t'il si on remplace while par if?
        @not_empty.wait(@mutex) while @contents.size == 0
        elem = @contents[0]
        _debug_ "#{self}#peek => ... #{elem}"
      end

      elem
    end

    # Indique la fermeture d'un canal.
    #
    # Mis en oeuvre en transmettant la valeur speciale EOS.
    #
    # @return [self]
    # @ensure Les appels subsequents a get vont retourner EOS
    #      apres que le contenu deja present aura ete lu.
    #
    def close
      put EOS

      self
    end

    # Permet d'executer un bloc pour chacun des elements obtenus d'un
    # canal.
    #
    # L'iteration se termine quand la valeur speciale EOS est
    # rencontree -- parce qu'elle a ete transmise explicitement par un
    # put ou implicitement par un close.
    #
    # Note: la valeur EOS n'est pas transmise au bloc.
    #
    # @param block Le bloc a executer
    # @require Le bloc recoit un argument, qui est un element du flux a traiter
    # @ensure Le bloc est execute pour chaque element du flux, sauf le EOS final
    #
    def each( &block )
      DBC.require( block.arity != 0,
                   "*** Le bloc passe a each doit avoir au moins un parametre:\n" <<
                   "    block = #{block}\n" <<
                   "    block.arity = #{block.arity}\n" <<
                   "    block.parameters = #{block.parameters}\n" )

      while (v = get) != EOS
        yield v
      end
    end

    # Obtient tous les elements du canal.
    #
    # @param [Bool,nil] immediate Si true alors ne bloque pas et
    #   retourne le contenu courant. Si false, alors ne retourne que
    #   lorsque la fin de canal est rencontree
    # @return [Array] immediate => tous les elements presentement dans le canal, sans bloquer
    # @return [Array] !immediate => tous les elements jusqu'au EOS, en bloquant si necessaire
    #
    # @ensure empty?
    #
    def get_all( immediate = nil )
      # Defined mostly for testing purpose.

      # We want to see what is currently there
      if immediate
        elems = nil
        @mutex.synchronize do
          elems = @contents.clone
        end
        @not_full.signal
        return elems
      end

      # We want to see the full contents, waiting till it is complete.
      elems = []
      loop do
        elem = get
        @not_full.signal
        break if elem == EOS
        elems << elem
      end
      @eos_encountered = true

      elems
    end

    @next_id = 0

    def self.next_id
      r = @next_id
      @next_id += 1

      r.to_s
    end
  end
end
