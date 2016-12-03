module PRuby

  # Un pipeline est compose d'une suite de noeuds (aka. "nodes",
  # "stages", etages) connectes entre eux. Un pipeline possede un
  # canal d'entree et un canal de sortie.  On peut lancer l'execution
  # d'un pipeline (avec run) puis attendre qu'il se termine (avec
  # join). On peut aussi connaitre la/les valeur/s finale/s
  # retournee/s par son/ses threads associes (avec value).
  #
  # Un Pipeline est en fait une classe purement abstraite, puisque
  # chaque noeud d'un Pipeline est aussi une instance d'une
  # sous-classe de Pipeline. Il s'agit donc d'un cas typique du patron
  # "composite", illustre par le diagramme de classes ci-joint.
  #
  #
  #                      ___________________
  #                      |                 |  1..*
  #                      |    Pipeline     |/___________________________
  #                      |_________________|\                           |
  #                               /\                                    |
  #                              ----                                   |
  #                                |                                    |
  #                                |                                    |
  #           |--------------------|---------------------|              |
  #           |                    |                     |              |
  #   ________|__________  ________|__________   ________|__________    |
  #   |                 |  |                 |   |                 |    |
  #   |    ProcNode     |  |  PipelineNode   |   |   FarmNode      |    |
  #   |_________________|  |_________________|   |_________________|    |
  #                                 |                    |              |
  #                                 |--------------------|---------------
  #
  # @abstract
  #
  class Pipeline

    # @abstract
    # Le canal d'entree
    # @!parse attr_reader :input_channel
    # @return [Channel]
    #
    def input_channel
      fail "*** La methode input_channel doit etre redefinie dans une sous-classe"
    end

    # @abstract
    # Le canal de sortie
    # @!parse attr_reader :output_channel
    # @return [Channel]
    #
    def output_channel
      fail "*** La methode output_channel doit etre redefinie dans une sous-classe"
    end

    # @abstract
    # @require !input_channel_connected?
    #
    def input_channel=( _ch )
      fail "*** La methode input_channel=() doit etre redefinie dans une sous-classe"
    end

    # @abstract
    # @require !output_channel_connected?
    #
    def output_channel=( _ch )
      fail "*** La methode output_channel=() doit etre redefinie dans une sous-classe"
    end

    # Determine si le canal d'entree du pipeline est connecte.
    # @return [Bool]
    #
    def input_channel_connected?
      input_channel
    end

    # Determine si le canal de sortie du pipeline est connecte.
    # @return [Bool]
    #
    def output_channel_connected?
      output_channel
    end

    # Determine si le noeud est une source, donc qui ne recoit rien du canal d'entree.
    # @return [Bool]
    #
    def source?
      @source_ou_sink == :source
    end

    # Determine si le noeud est un puits, donc qui n'emet rien sur le canal de sortie.
    # @return [Bool]
    #
    def sink?
      @source_ou_sink == :sink
    end

    # Connecte deux pipelines entre eux.
    #
    # @param [Pipeline] other L'autre pipeline a connecter avec le premier (self)
    # @return [self]
    # @ensure Ajoute other comme etage (noeud) additionel au pipeline courant
    #
    def |( other )
      add_stage( other )
    end

    # Connecte une source a un pipeline ou un pipeline a un puits.
    #
    # @require L'un ou l'autre des deux elements a connecter doit etre une source ou un puits
    # @return [self]
    # @note Identique a |. Utilise simplement parce que plus "image"
    # @note Attention: la priorite de ">>" differe de celle de "|" !?!?
    #
    def >>( other )
      DBC.require( source? || other.class == Proc || other.sink?,
                   "*** Cette operation ne peut etre utilisee qu'avec une source (a gauche) ou un sink (a droite)" )
      add_stage( other )
    end

    # Indique si le thread associe au pipeline a termine son execution
    # @return [Bool]
    #
    def terminated?
      @terminated
    end


    # Cree un lien de feedback, avec un nouveau canal, entre la sortie
    # et l'entree du pipeline
    #
    # @require Les canaux d'entre et de sortie ne doivent pas deja etre connectes
    # @return [self]
    # @ensure Un nouveau canal connecte la sortie a l'entree
    #
    def wrap_around!
      DBC.require !input_channel_connected?,  "*** L'entree du pipeline est deja connectee"
      DBC.require !output_channel_connected?, "*** La sortie du pipeline est deja connectee"

      chan = Channel.new
      self.output_channel = chan
      self.input_channel = chan
      self
    end

    # Lance un/des thread/s pour executer la/les tache/s associee/s
    # au/x noeud/s.  Donc, s'il s'agit d'un noeud composite, alors
    # lance l'execution des noeuds internes.
    #
    # @param [Bool] no_wait Si :NO_WAIT, alors on n'attend pas que
    #    l'execution des noeuds internes soit terminee pour retourner
    # @return [self]
    # @ensure Si no_wait != :NO_WAIT, alors l'execution des noeuds
    #   internes est terminee
    #
    def run( no_wait = nil )
      @terminated = false

      inner_nodes.map { |s| s.run :NO_WAIT }
      join unless no_wait == :NO_WAIT

      self
    end

    # Bloque jusqu'a ce que l'execution du/des noeud/s soit
    # terminee. Si deja termine, alors NOOP.
    #
    # @return [self]
    # @ensure L'execution des noeuds internes est terminee
    #
    def join
      return if terminated?

      inner_nodes.map(&:join)
      @terminated = true

      self
    end

    alias_method :input, :input_channel
    alias_method :output, :output_channel

    private
    def mk_node( other )
      return other if other.kind_of? Pipeline

      ProcNode.new other
    end
  end


  private

  # Classe atomique de base, donc non composite, donc celle a qui sera
  # associe un Thread actif.
  #
  class ProcNode < Pipeline
    # Le canal d'entree.
    # @!parse attr_reader :input_channel
    # @return [Channel]
    #
    attr_reader :input_channel

    # Le canal de sortie.
    # @!parse attr_reader :output_channel
    # @return [Channel]
    attr_reader :output_channel


    # Constructeur pour un noeud atomique (non composite).
    #
    # @param [Proc] body Le lambda a executer
    # @param [:source,:sink, nil] source_ou_sink Indique si le noeud est une source ou un puits ou ni l'un ni l'autre
    # @require body.arity == 1
    # @return [Pipeline] Le nouvel objet
    #
    def initialize( body, source_ou_sink = nil )
      DBC.check_type( body, Proc,
                      "*** Dans creation d'un pipeline, l'argument n'est pas un lambda (class = #{body.class}" )
      DBC.assert( body.arity.abs >= 2,
                  "*** Dans creation d'un pipeline, le lambda n'a pas deux arguments:\n" <<
                  "    body.arity = #{body.arity}\n" <<
                  "    body.parameters = #{body.parameters}\n"
                  )

      @body = body
      @input_channel = nil
      @output_channel = nil
      @source_ou_sink = source_ou_sink
    end

    # @require !input_channel_connected?
    def input_channel=( ch )
      DBC.require !input_channel_connected?, "*** Le canal d'entree #{input_channel} est deja connecte"
      @input_channel = ch
    end

    # @require !output_channel_connected?
    def output_channel=( ch )
      DBC.require !output_channel_connected?, "*** Le canal de sortie #{output_channel} est deja connecte"
      @output_channel = ch
    end

    # Obtient le prochain element du canal d'entree (simple proxy).
    #
    # @require input_channel_connected?
    # @return (see Channel#get)
    # @ensure (see Channel#get)
    #
    def get
      DBC.require input_channel_connected?, "*** Le canal input_channel n'est pas connecte"
      @input_channel.get
    end

    # Lit le prochain element du canal d'entree (simple proxy), mais le retirer
    #
    # @require input_channel_connected?
    # @return (see Channel#peek)
    # @ensure (see Channel#eek)
    #
    def peek
      DBC.require input_channel_connected?, "*** Le canal input_channel n'est pas connecte"
      @input_channel.peek
    end

    # Ecrit un element sur le canal de sortie.
    #
    # @require output_channel_connected?
    # @param (see Channel#put)
    # @return (see Channel#put)
    # @ensure (see Channel#put)
    #
    def put( c )
      DBC.require output_channel_connected?, "*** Le canal output_channel n'est pas connecte"
      @output_channel.put c
    end

    # Cree un pipeline avec self comme 1er etage et other comme 2e etage
    # @param [Proc, Pipeline] other
    # @return [Pipeline]
    def add_stage( other )
      PipelineFactory.pipeline self, other
    end

    # Lance un thread pour executer la tache associee
    # au noeud.
    #
    # @param [Bool] no_wait Si :NO_WAIT, alors on n'attend pas que
    #    l'execution soit terminee pour retourner
    # @return [self]
    # @ensure Si no_wait != :NO_WAIT, alors l'execution est terminee
    #
    def run( no_wait = nil )
      @terminated = false

      @thread = Thread.new { @value = @body.call(input_channel, output_channel) }
      @thread.join unless no_wait == :NO_WAIT

      self
    end

    # Bloque jusqu'a ce que l'execution de la tache soit
    # terminee. Si deja termine, alors NOOP.
    #
    # @return [self]
    # @ensure L'execution est terminee
    #
    def join
      return if terminated?

      @thread.join
      @terminated = true

      self
    end

    # @return [Object] La valeur finale produite par le thread associe au noeud.
    # @ensure Le thread a termine son activite
    #
    def value
      join
      @value
    end

    # @return [String]
    def to_s
      if source?
        "Source(#{output_channel})"
      elsif sink?
        "Sink(#{input_channel})"
      else
        "ProcNode(#{input_channel}, #{output_channel})"
      end
    end

    alias_method :input, :input_channel
    alias_method :output, :output_channel
  end

  private

  class PipelineNode < Pipeline
    # Retourne les differents internes noeuds du pipeline.
    # @return [Array<Pipeline>]
    def inner_nodes
      @stages
    end

    # Cree un nouvel objet pour un pipeline
    #
    # @param [Proc] first_stage Le premier etage du pipeline
    # @return [Pipeline]
    #
    def initialize( first_stage )
      @stages = [ mk_node(first_stage) ]
    end

    # Le canal d'entree.
    # @!parse attr_reader :input_channel
    # @return [Channel]
    #
    def input_channel
      @stages.first.input_channel
    end

    # Le canal de sortie.
    # @!parse attr_reader :output_channel
    # @return [Channel]
    #
    def output_channel
      @stages.last.output_channel
    end

    def input_channel=( ch )
      @stages.first.input_channel = ch
    end

    def output_channel=( ch )
      @stages.last.output_channel = ch
    end

    # Ajoute other comme etage additionnel du pipeline courant
    # @param [Proc, Pipeline] other
    # @return [self]
    def add_stage( other )
      other = mk_node( other )

      DBC.require( !output_channel_connected?,
                   "*** Le canal de sortie de la partie gauche du pipeline est deja connectee !?" )
      DBC.require( !other.input_channel_connected?,
                   "*** Le canal d\'entree de la partie droite du pipeline est deja connectee !?" )

      chan = Channel.new
      self.output_channel = chan
      other.input_channel = chan
      @stages << other

      self
    end

    # @return [Array] Le tableau des valeurs produites par chacun des etages
    # @ensure Les threads des noeuds internes ont tous termine leur activite
    #
    def value
      join
      @stages.map( &:value )
    end

    # @return [String]
    def to_s
      "PipelineNode( " + @stages.map(&:to_s).join(" | ") + " )"
    end
  end

  private

  class FarmNode < Pipeline

    # Cree un nouvel objet pour une ferme
    #
    # @param [Proc] proc Le Proc (lambda) pour le travailleur a activer
    # @param [Fixnum] nb Le nombre d'instances desirees
    # @return [Pipeline]
    #
    def initialize( proc, nb )
      DBC.require proc.class == Proc, "*** Argument de FarmNode doit etre un Proc"

      # @!visibility private
      def self.emitter(nb)
        lambda do |cin, cout|
          cin.each { |v| cout << v }
          nb.times do
            cout << EOS
          end
        end
      end

      # @!visibility private
      def self.collector(nb)
        lambda do |cin, cout|
          nb_eos = 0
          while nb_eos < nb
            v = cin.get
            if v == EOS
              nb_eos += 1
            else
              cout << v
            end
          end
          cout << EOS
        end
      end

      c_ew = Channel.new
      c_wc = Channel.new.with_multiple_writers(nb)
      @emitter = mk_node emitter(nb)
      @collector = mk_node collector(nb)
      @workers = (0...nb).map do
        pn = mk_node proc
        pn.input_channel = c_ew
        pn.output_channel = c_wc
        pn
      end
      @emitter.output_channel = c_ew
      @collector.input_channel = c_wc
    end

    # Le canal d'entree.
    # @!parse attr_reader :input_channel
    # @return [Channel]
    #
    def input_channel
      @emitter.input_channel
    end

    # Le canal de sortie.
    # @!parse attr_reader :output_channel
    # @return [Channel]
    #
    def output_channel
      @collector.output_channel
    end

    def input_channel=( ch )
      @emitter.input_channel = ch
    end

    def output_channel=( ch )
      @collector.output_channel = ch
    end

    # Retourne les differents internes noeuds de la ferme.
    # @return [Array<Pipeline>]
    def inner_nodes
      [@emitter] + @workers + [@collector]
    end

    # @return [String]
    def to_s
      "FarmNode(#@emitter |> #{@workers.map(&:to_s).join("|")} |> #@collector) "
    end

    # @return [Array] Le tableau des valeurs produites par chacun des travailleurs
    # @ensure Les threads des noeuds internes ont tous termine leur activite
    #
    def value
      join
      @workers.map(&:value)
    end
  end

end
