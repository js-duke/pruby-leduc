module PRuby

  #
  # Constantes speciales pour les noeuds de types "fastflow".
  #
  GO_ON = :PRUBY_GO_ON
  NONE  =  GO_ON           # Alias
  MANY  = :PRUBY_MANY

  class Stream
    include Enumerable

    #
    # Taille par defaut du buffer alloue pour le Channel d'un Stream.
    #
    # Preferable d'utiliser 1 dans les tests pour assurer que les
    # methodes fonctionnent correctement meme lorsque le buffer est
    # petit.  Evidemment, il est preferable d'utiliser une taille
    # superieure en pratique, pour permettre aux threads de generer
    # plusieurs elements avant de, possiblement, bloquer parce que le
    # tampon de communication est plein.
    #
    DEFAULT_BUFFER_SIZE = 10


    # @!visibility private
    #
    # Les threads associes a un Stream.
    #
    # @return [Array<Thread>]
    #
    attr_reader :threads

    #
    # La taille du buffer associe au Channel d'un Stream.
    #
    # @return [Fixnum]
    #
    attr_accessor :buffer_size

    # @!visibility private
    # Nouveau Stream.
    # @param [Channel] channel Le canal d'entree
    # @param [Array<Thread>] threads Les threads qui vont utiliser ce Stream
    #
    def initialize( channel, threads = [] )
      @channel = channel
      @threads = threads
    end
    private_class_method :new

    # @!visibility private
    #
    # Objet bidon utilise dans les methodes de classe pour creer de
    # nouveaux streams.
    #
    @@dummy_stream = Stream.send :new, nil


    # Cree un stream a partir des elements d'une source externe.
    # Cette source peut etre n'importe quel objet pouvant repondre au
    # message #each, sinon au message #each_char, sinon etre un nom de
    # fichier. Dans ce dernier cas, ce sont les lignes du fichier qui
    # seront emises, l'une apres l'autre, sur le stream.
    #
    # @param [#each, String] source La source qui fournira les elements a emettre
    # @option options [nil, :string, :filename] source_kind La sorte de source
    # @option options [Fixnum] :nb_threads Le nombre de threads avec lesquels on desire que le traitement soit fait
    # @option options [Fixnum] :buffer_size La taille de buffer a utiliser pour le Channel de sortie
    # @return [Stream] Le stream cree
    #
    # @note Si un objet repondant au message :each est est fourni en
    #    argument, alors ce sont les elements enumeres par :each qui
    #    seront emis sur le stream. Si une chaine est fournie et
    #    qu'aucun argument n'est specifie pour source_kind, alors ce
    #    sont les caracteres de la chaine qui sont emis. Par contre,
    #    si une chaine est fournie et que l'argument :filename est
    #    specifie pour source_kind, alors ce sont les *lignes du
    #    fichier* qui sont emises.  De plus, dans le cas d'un fichier:
    #    i) une exception sera lancee si aucun fichier avec le nom
    #    indique n'existe; ii) les lignes emises contiendront le saut
    #    de ligne final.
    #
    def self.source( source, options = {} )
      DBC.require( source.respond_to?(:each) || source.respond_to?(:each_char),
                   "*** La source doit repondre a :each, :each_char\
                    ou etre un nom de fichier" )
      DBC.check_value( options[:source_kind],
                       [nil, :string, :file_name, :filename],
                       "*** Les sortes acceptees sont :filename et :string" )

      DBC.require( Stream.un_seul_thread?(options),
                   "*** La generation d'une source doit se faire sequentiellement" )

      @@dummy_stream.send :mk_stream_with_threads, options do |channel|
        if source.respond_to?(:each_char) && [:file_name, :filename].include?(options[:source_kind])
          File.open(source, 'r') do |f|
            f.each_line { |line| channel << line }
          end
        elsif source.respond_to?(:each)
          source.each { |x| channel << x }
        else
          source.each_char { |c| channel << c }
        end
      end
    end

    #
    # Genere une serie de valeurs *potentiellement infinie*.
    #
    # Termine la generation quand le bloc retourne nil comme resultat.
    #
    # @yieldparam [void]
    # @yieldreturn [Object, nil] L'element a emettre sur le stream de sortie, si non nil. Si nil, alors le processus de generation est termine et le canal de sortie est ferme.
    #
    # @return [Stream] Le stream cree
    # @option (see .source)
    #
    def self.generate( options = {} )
      @@dummy_stream.send :mk_stream_with_threads, options do |channel|
        until (r = yield).nil?
          channel << r
        end
      end
    end

    ##########################################################
    # Methodes d'instance.
    ##########################################################

    # @!visibility private
    def mk_stream_with_threads( options = {} )
      buffer_size = options[:buffer_size] || DEFAULT_BUFFER_SIZE
      DBC.require( buffer_size > 0,
                   "*** La taille d'un buffer de stream doit etre positive\
                   (i.e., pas de buffer non-borne)" )

      nb_threads = options[:nb_threads] || 1
      DBC.require( nb_threads >= 1,
                   "*** Il faut au moins un thread pour generer un nouveau Stream" )

      channel = Channel.new nil, buffer_size, [], true
      channel.with_multiple_writers(nb_threads) if nb_threads > 1

      s = Stream.send :new, channel, threads

      nb_threads.times do
        t = Thread.new do
          yield channel
          channel.close
        end
        s.threads << t
      end

      s
    end

    private :mk_stream_with_threads

    #
    # Enumere, sequentiellement, les elements du stream, et applique
    # le bloc sur ces elements.
    #
    # Ne genere pas un nouveau stream.
    #
    # @yieldparam [Object] x Le prochain element obtenu du canal associe au stream
    # @return [void]
    #
    def each
      @channel.each do |x|
        yield x
      end

      nil
    end

    ###################################################################
    # Methodes de transformations de streams.  Donc, chacune des
    # methodes qui suit s'applique sur un stream pour produire un
    # nouveau stream. Ce dernier stream est genere de facon
    # parallelle, a l'aide d'un ou plusieurs threads.
    ###################################################################

    #
    # Applique une fonction (un bloc) sur chacun des elements du stream.
    #
    # @yieldparam [Object] x Un element du stream d'entree
    # @yieldreturn [Object] L'element a emettre sur le stream de sortie
    #
    # @return [Stream]
    #
    def map( options = {} )
      mk_stream_with_threads( options ) do |channel|
        each do |x|
          channel << yield( x )
        end
      end
    end
    alias_method :collect, :map

    #
    # Selectionne les elements du stream qui satisfont une fonction (un bloc).
    #
    # @yieldparam [Object] x Un element du stream d'entree
    # @yieldreturn [Bool] True si l'argument satisfait la condition, false sinon
    #
    # @return [Stream]
    #
    def filter( options = {} )
      mk_stream_with_threads( options ) do |channel|
        each do |x|
          channel << x if yield(x)
        end
      end
    end
    alias_method :select, :filter

    #
    # Selectionne les elements du stream qui ne satisfont pas une
    # fonction (un bloc).
    #
    # @yieldparam [Object] x Un element du stream d'entree
    # @yieldreturn [Bool] True si l'argument ne satisfait pas la condition, false sinon
    # @return [Stream]
    #
    def reject( options = {} )
      mk_stream_with_threads( options ) do |channel|
        each do |x|
          channel << x unless yield(x)
        end
      end
    end

    #
    # Tri les elements d'un stream.
    #
    # Le bloc a utiliser pour comparer les elements est optionnel.
    #
    # @yieldparam [Object] x Le premier element a comparer
    # @yieldparam [Object] y Le deuxieme element a comparer
    # @yieldreturn [<-1, 0, 1>]
    #
    # @return [Stream]
    #
    # @note Pour l'instant, ne peut s'executer qu'avec un seul thread
    #
    # @note Le stream d'entree complet doit etre recu avant que des
    #       elements puissent etre emis sur le stream de sortie.
    #
    def sort( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un tri avec sort doit se faire sequentiellement" )

      cin = @channel
      mk_stream_with_threads do |channel|
        if block_given?
          sorted = cin.sort { |x, y| yield( x, y ) }.each
        else
          sorted = cin.sort.each
        end
        sorted.each do |x|
          channel << x
        end
      end
    end

    #
    # Applique un traiement arbitraire sur chacun des elements du
    # stream, et retourne le stream d'entre sans aucune modification.
    #
    # @yieldparam [Object] x Un element du stream d'entree
    # @yieldreturn [void]
    #
    # @return [Stream]
    #
    def peek( options = {} )
      mk_stream_with_threads( options ) do |channel|
        each do |x|
          yield x
          channel << x
        end
      end
    end

    #
    # Filtre les elements du stream d'entree pour assurer qu'il n'y
    # ait qu'une seule occurrence de chaque element dans le stream de
    # sortie.
    #
    # @return [Stream]
    #
    def uniq( options = {} )
      vus = []
      mutex = Mutex.new
      mk_stream_with_threads( options ) do |channel|
        each do |x|
          mutex.synchronize do
            unless vus.include? x
              channel << x
              vus << x
            end
          end unless vus.include? x
        end
      end
    end

    #
    # Applique une fonction (un bloc) sur chacun des elements du
    # stream d'entree.  La fonction produit en sortie un Array
    # d'elements (contenant 0, 1 ou plusieurs elements), lesquels
    # arrays sont ensuite concatenes dans le stream de sortie.
    #
    # @yieldparam [Object] x Un element du stream d'entree
    # @yieldreturn [#each] Un ou plusieurs elements accessibles par l'intermediaire d'appels a #each
    #
    # @return [Stream]
    #
    def flat_map( options = {} )
      mk_stream_with_threads( options ) do |channel|
        each do |x|
          yield( x ).each do |y|
            channel << y
          end
        end
      end
    end

    #
    # Prend les n premiers elements du stream.
    #
    # @param [Fixnum] n Nombre d'elements a prendre au debut du stream
    # @return [Stream]
    # @note Ne peut se faire qu'avec un seul thread
    #
    def take( n, options = {} )
      DBC.require( n >= 0,
                   "*** Dans take: n doit etre >= 0 (n = #{n})" )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec take doit se faire sequentiellement" )

      cin = @channel
      mk_stream_with_threads do |channel|
        while n > 0 && !cin.eos?
          channel << cin.get
          n -= 1
        end
      end
    end

    #
    # Supprime (laisse tomber) les n premiers elements du stream.
    #
    # @param [Fixnum] n Nombre d'elements a laisser tomber au debut du stream
    # @return [Stream]
    # @note Ne peut se faire qu'avec un seul thread
    #
    def drop( n, options = {} )
      DBC.require( n >= 0,
                   "*** Dans drop: n doit etre >= 0 (n = #{n})" )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec drop doit se faire sequentiellement" )

      cin = @channel
      mk_stream_with_threads do |channel|
        while n > 0 && !cin.eos?
          cin.get
          n -= 1
        end
        each do |x|
          channel << x
        end
      end
    end


    # Prend les elements du  stream tant qu'ils satisfont la condition
    # (bloc).  Termine  le stream de  sortie des qu'un element  qui ne
    # satisfait pas la condition est rencontree.
    #
    # @yieldparam [Object] x Un element du stream d'entree
    # @yieldreturn [Bool]
    #
    # @return [Stream]
    #
    # @note Ne peut se faire qu'avec un seul thread
    #
    def take_while( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec take_while doit se faire sequentiellement" )

      cin = @channel
      mk_stream_with_threads do |channel|
        cin.each do |x|
          if yield( x )
            channel << x
          else
            break
          end
        end
      end
    end

    # Laisse tomber les elements du stream tant qu'ils satisfont la
    # condition (bloc).  Ajoute ensuite tous les elements subsequent
    # dans le stream de sortie.
    #
    # @yieldparam [Object] x Un element du stream d'entree
    # @yieldreturn [Bool]
    #
    # @return [Stream]
    #
    # @note Ne peut se faire qu'avec un seul thread
    #
    def drop_while( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec drop_while doit se faire sequentiellement" )

      cin = @channel

      mk_stream_with_threads do |channel|
        on_conserve = false
        cin.each do |x|
          if on_conserve
            channel << x
          else
            unless yield(x)
              on_conserve = true
              channel << x
            end
          end
        end
      end
    end

    # Regroupe les elements du stream selon la valeur generee par
    # l'application du bloc.
    #
    # @yieldparam [Object] x Un element du stream d'entree
    # @yieldreturn [Object] La valeur a utiliser pour le regroupement
    #
    # @return [Stream]
    #
    # @note Ne peut se faire qu'avec un seul thread
    #
    def group_by( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec group_by doit se faire sequentiellement" )

      cin = @channel
      mk_stream_with_threads do |channel|
        h = cin.group_by { |x| yield x }
        h.each_pair do |k, v|
          if value = options[:merge_value] || options[:map_value]
            channel << [k, v.reduce([]) { |a, x| a << value.call(x) }]
          else
            channel << [k, v]
          end
        end
      end
    end

    # @!visibility private
    def collect_grouping_by( options = {}, &block )
      group_by(options, &block).to_a
    end

    # @!visibility private
    def group_by_key( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec group_by doit se faire sequentiellement" )

      cin = @channel
      mk_stream_with_threads do |channel|
        h = cin.group_by { |x| x.first }
        h.each_pair do |k, v|
          channel << [k, v.reduce([]) { |a, x| a << x.last }]
        end
      end
    end

    # @!visibility private
    def reduce_by_key( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec reduce_by doit se faire sequentiellement" )

      cin = @channel
      mk_stream_with_threads do |channel|
        h = cin.group_by { |x| x.first }
        h.each_pair do |k, v|
          channel << [k, v.map(&:last).reduce { |a, x| yield( a, x ) }]
        end
      end
    end

    # @!visibility private
    def combine_values( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec combine_values doit se faire sequentiellement" )

      cin = @channel
      mk_stream_with_threads do |channel|
        cin.each do |k, v|
          channel << [k, v.reduce { |a, x| yield( a, x ) }]
        end
      end
    end

    # @!visibility private
    def sum_by_key( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec sum_by_key doit se faire sequentiellement" )

      cin = @channel
      mk_stream_with_threads do |channel|
        cin.each do |k, v|
          channel << [k, v.reduce(0) { |a, x| a + yield(x) }]
        end
      end
    end

    #
    # Applique un traitement a la go sur le stream.
    #
    # Le bloc recu doit donc recevoir deux arguments: un canal d'entree
    # et un canal de sortie.  Le code dans le bloc manipule ensuite de
    # facon explicite ces canaux, donc avec get/put/each, etc.
    #
    # @yieldparam [Channel] cin Le canal du stream d'entree
    # @yieldparam [Channel] channel Le canal du stream de sortie
    # @yieldreturn [void]
    #
    # @return [Stream]
    #
    # @note Ne peut se faire qu'avec un seul thread
    #
    def go( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec go doit se faire sequentiellement" )
      cin = @channel
      mk_stream_with_threads do |channel|
        yield( cin, channel )
      end
    end

    #
    # Transforme un stream avec un changement etat.
    #
    # On specifie l'etat initial lors de l'appel a la methode.  Le
    # bloc execute doit recevoir deux arguments: l'etat courant et
    # l'element a traiter.  Il doit aussi retourner deux resultats
    # (Array): le nouvel etat et la valeur a emettre sur le stream de
    # sortie suite au traitement de l'element recu.  Un tel traitement
    # signifie donc une execution strictement sequentielle.
    #
    # @option options [Object] initial_state Valeur initiale de l'etat
    # @option options [Proc, :STATE, :EMIT_STATE] at_eos Traitement a
    #     effectuer lorsque la fin du stream est rencontree.  Si Proc,
    #     alors l'etat est transmis au Proc. Si :STATE ou :EMIT_STATE,
    #     l'etat est simplement emis sur le stream de sortie
    #
    # @yieldparam [Object] state L'etat courant
    # @yieldparam [Object] x  La valeur a traiter du stream d'entree
    # @yieldreturn [Array<Object>] Le nouvel etat courant et la valeur a emettre sur le canal du stream de sortie (si non nil)
    #
    # @return [Stream]
    #
    # @note Ne peut se faire qu'avec un seul thread
    #
    def stateful( options = {} )
      DBC.require( Stream.un_seul_thread?(options),
                   "*** Un traitement avec stateful doit se faire sequentiellement" )

      state = options[:initial_state]
      cin = @channel
      mk_stream_with_threads do |channel|
        cin.each do |x|
          state, result = yield( state, x )
          channel << result
        end
        at_eos = options[:at_eos]
        if at_eos.is_a?(Proc)
          channel << at_eos.call(state)
        elsif at_eos == :STATE || at_eos == :EMIT_STATE
          channel << state
        elsif at_eos
          channel << at_eos
        end
      end
    end

    # @!visibility private
    #
    # Transforme un stream dans le style fastflow.
    #
    # @option options [Bool, Object] stateful Si true alors l'etat initial est specifie par initial_state. Si non-nil/non-false, alors sert aussi pour l'etat initial. Si nil/false, alors pas d'etat.
    # @option options [Object] initial_state Valeur initiale de l'etat
    # @option options [Proc, :STATE, :EMIT_STATE] at_eos Traitement a
    #     effectuer lorsque la fin du stream est rencontree.  Si Proc,
    #     alors l'etat est transmis au Proc. Si :STATE ou :EMIT_STATE,
    #     l'etat est simplement emis sur le stream de sortie. (Dans le cas :stateful, evidemment.)
    #
    # @yieldparam [Object] state L'etat courant, si :stateful
    # @yieldparam [Object] x La valeur a traiter du stream d'entree
    # @yieldreturn [Array<Object>, Object] Le nouvel etat courant et la valeur a emettre sur le canal du stream de sortie (si non nil) si :stateful, sinon uniquement la valeur a emettre
    #
    # @return [Stream]
    #
    # @note Si le resultat retourne par le bloc est nil ou GO_ON,
    #     alors rien n'est emis sur le stream de sortie pour cet
    #     element.  Si le resultat est un Array dont le premier
    #     element est :MANY, alors tous les autres elements du Array
    #     sont emis sur le canal de sortie.
    def fastflow( options = {} )
      DBC.require( !options[:stateful] || Stream.un_seul_thread?(options),
                   "*** Un traitement stateful avec fastflow doit se faire sequentiellement" )

      if stateful = options[:stateful]
        current_state = stateful == true ? options[:initial_state] : stateful
      end

      cin = @channel
      mk_stream_with_threads do |channel|
        cin.each do |x|
          if stateful
            current_state, result = yield( current_state, x )
          else
            result = yield( x )
          end
          unless result.nil? || result == GO_ON
            if result.class == Array && result[0] == MANY
              (1...result.size).each do |i|
                channel << result[i]
              end
            else
              channel << result
            end
          end
        end
        if at_eos = options[:at_eos]
          res_at_eos = stateful ? at_eos.call(current_state) : at_eos.call
        end
        channel << res_at_eos unless res_at_eos.nil? || res_at_eos == GO_ON
      end
    end

    # @!visibility private
    def ff_node_stateful( &block )
      fastflow( stateful: true, &block )
    end

    # @!visibility private
    def ff_node_with_state( &block )
      fastflow( stateful: true, &block )
    end

    # @!visibility private
    def ff_node( options = {} )
      DBC.require( !options[:stateful] || Stream.un_seul_thread?(options),
                   "*** Un traitement stateful avec ff_node doit se faire sequentiellement" )

      if stateful = options[:stateful]
        current_state = stateful == true ? options[:initial_state] : stateful
      end

      cin = @channel
      mk_stream_with_threads do |channel|
        cin.each do |x|
          if stateful
            current_state, result = yield( current_state, x, channel )
          else
            result = yield( x, channel )
          end
          unless result.nil? || result == GO_ON
            channel << result
          end
        end
        if at_eos = options[:at_eos]
          res_at_eos = stateful ? at_eos.call(current_state, channel) : at_eos.call(channel)
        end
        channel << res_at_eos unless res_at_eos.nil? || res_at_eos == GO_ON
      end
    end

    # @!visibility private
    def parallel_do( options = {} )
      DBC.require( !options[:stateful] || Stream.un_seul_thread?(options),
                   "*** Un traitement stateful avec parallel_do doit se faire sequentiellement" )

      if stateful = options[:stateful]
        current_state = stateful == true ? options[:initial_state] : stateful
      end

      cin = @channel
      mk_stream_with_threads do |channel|
        cin.each do |x|
          if stateful
            current_state, result = yield( current_state, x, channel )
          else
            yield( x, channel )
          end
        end
        if at_eos = options[:at_eos]
          res_at_eos = stateful ? at_eos.call(current_state, channel) : at_eos.call(channel)
        end
        channel << res_at_eos unless res_at_eos.nil? || res_at_eos == GO_ON
      end
    end

    # @!visibility private
    def apply_( proc, options = {} )
      DBC.require( !options[:stateful] || Stream.un_seul_thread?(options),
                   "*** Un traitement stateful avec parallel_do doit se faire sequentiellement" )

      if stateful = options[:stateful]
        current_state = stateful == true ? options[:initial_state] : stateful
      end

      cin = @channel
      mk_stream_with_threads do |channel|
        cin.each do |x|
          if stateful
            current_state, result = yield( current_state, x, channel )
          else
            proc.call( x, channel )
          end
        end
        if at_eos = options[:at_eos]
          res_at_eos = stateful ? at_eos.call(current_state, channel) : at_eos.call(channel)
        end
        channel << res_at_eos unless res_at_eos.nil? || res_at_eos == GO_ON
      end
    end

    # @!visibility private
    def tee( options = {} )
      nb_tees = options[:nb_outputs] || options[:nb_tees] || 2
      DBC.require( nb_tees >= 2,
                   "*** Le nombre de tees doit etre >= 2" )

      buffer_size = options[:buffer_size] || DEFAULT_BUFFER_SIZE
      DBC.require( buffer_size > 0,
                   "*** La taille d'un buffer de stream doit etre positive\
                   (i.e., pas de buffer non-borne)" )

      cin = @channel
      cout = (0...nb_tees).map { Channel.new nil, buffer_size, [], true }
      thread = Thread.new do
        cin.each do |x|
          (0...nb_tees).each do |i|
            cout[i] << x
          end
        end
        (0...nb_tees).each do |i|
          cout[i].close
        end
      end
      cout.map { |chan| Stream.send :new, chan, [thread] }
    end

    # @!visibility private
    def join( other, options = {} )
      by_key = options[:by_key]
      cin = @channel
      mk_stream_with_threads do |channel|
        hash = Hash.new
        cin.each do |k1_v1|
          k1, v1 = by_key ? [by_key.call(k1_v1), k1_v1] : k1_v1
          hash[k1] ||= []
          hash[k1] << v1
        end

        map_value = options[:merge_value] || options[:map_value]

        other.each do |k2_v2|
          k2, v2 = by_key ? [by_key.call(k2_v2), k2_v2] : k2_v2
          (hash[k2] || []).each do |v|
            if map_value
              channel << [k2, [map_value.call(v), map_value.call(v2)]]
            else
              channel << [k2, [v, v2]]
            end
          end
        end
      end
    end


    #
    # Itere une transformation de stream un certain nombre fixe de fois.
    #
    # @param [Fixnum] nb_iterations Nombre total de fois ou il faut proceder au traitement du stream de bout en bout
    #
    # @yieldparam [Stream] s Le stream a utiliser pour la nouvelle iteration
    # @yieldreturn [Stream] Le stream produit par l'iteration
    #
    # @return [Stream]
    #
    def iterate( nb_iterations )
      s = self
      nb_iterations.times do
        s = yield s
      end
      s
    end


    #
    # Applique une fonction sur le stream.
    #
    # La fonction est specifiee par une lambda-expression ou par un
    # bloc.  Cette fonction recoit un stream et retourne un stream.
    # Typiquement, elle utilisera les diverses operations sur les
    # streams.
    #
    # @param [Proc, nil] proc Une lambda-expression a appliquer sur self ou sinon un bloc
    #
    # @yieldparam [Stream] self Le stream courant
    # @yieldreturn [Stream]
    #
    # @return [Stream]
    #
    def apply( proc = nil )
      if block_given?
        yield self
      else
        DBC.require proc && proc.is_a?(Proc), "*** Dans apply: bloc ou proc argument doit etre specifie"
        proc.call self
      end
    end


    #
    # Cree un stream a partir d'un proc (avec apply) et le lie (le
    # concatene) au stream courant.
    #
    # Essentiellement, >> est un alias d'apply, mais qui s'appique
    # uniquement sur une lambda-expression.
    #
    # @param [Proc] proc Un lambda qui represente le traitement a faire sur le stream, via apply
    # @return [Stream] Un nouveau stream
    #
    # @note Voir .apply
    #
    def >>( proc )
      DBC.require proc.is_a?(Proc), "*** Dans >>: argument proc doit etre specifie"

      apply( proc )
    end

    #
    # Collecte les elements d'un stream dans un objet final
    # non-stream.
    #
    # Plus specifiquement, les objets recus pourront etre mis dans un
    # tableau -- nouveau ou ajoute a un tableau existant -- ou dans un
    # fichier.
    #
    # @param [Class,#<<,#puts,String] destination La destination des elements
    # @return [Array,nil] Un Array si la destination en est un, sinon nil
    # @ensure si destination == Array alors les elements du stream sont mis dans un nouveau tableau
    # @ensure si destination.respond_to?(:puts) ou destination.respond_to?(:<<), alors les elements recus du stream sont ajoutes avec la methode
    # @ensure si destination.class == String alors les elements recus sont ajoutes dans le fichier avec le nom indique (qui peut ne pas exister)
    #
    def sink( destination )
      # Si c'est simplement le nom de classe Array, on genere un
      # nouveau tableau pour recevoir les elements du Stream.
      destination = [] if destination == Array

      if destination.class == String
        # On ajoute les elements au fichier ayant le nom indique.
        File.open( destination, 'a+' ) do |f|
          each { |v| f.puts v }
        end
        result = nil
      elsif destination.respond_to?( :puts )
        # On ajoute les elements du Stream avec :puts
        each { |v| destination.puts v }
        result = nil
      elsif destination.respond_to?( :<< )
        # On ajoute les elements du Stream avec :<<
        each { |v| destination << v }
        result = destination
      end

      # On termine les threads -- requis pour ceux qui generent de
      # facon potentiellement infinie.
      threads.each do |t|
        Thread.kill t if t.alive?
      end

      result
    end

    #
    # Collecte les elements du Stream dans un tableau, fraichement
    # alloue.
    #
    # @return [Array]
    #
    def to_a
      sink []
    end


    private
    def self.un_seul_thread?( options )
      options[:nb_threads].nil? || options[:nb_threads] == 1
    end
  end
end
