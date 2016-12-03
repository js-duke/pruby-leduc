module PRuby

  # Fabrique (factory) pour creer diverses sortes de Pipeline.
  #
  class PipelineFactory

    # Cree un pipeline contenant au moins un noeud (un etage).
    #
    # @param [liste de Pipeline ou Proc] args Liste des noeuds a inclure dans le nouveau pipeline
    # @require args.size >= 1
    # @return [Pipeline] Le pipeline nouvellement cree
    #
    def self.pipeline( *args )
      DBC.require args.size >= 1, "*** Il doit y avoir au moins un element dans un pipeline"

      first_stage = args.shift
      pipe = PipelineNode.new first_stage
      args.each do |arg|
        pipe.add_stage arg
      end

      pipe
    end

    # Cree une ferme de travailleurs.
    #
    # @param [Proc] proc Un lambda qu'on veut utiliser comme travailleur
    # @param [Fixnum] nb Le nombre de travailleurs qu'on desire avoir dans la ferme
    # @require nb >= 1
    # @return [Pipeline] La ferme nouvellement creee
    #
    def self.farm( proc, nb )
      DBC.require nb >= 1, "*** Une ferme doit avoir au moins 1 travailleur"

      FarmNode.new proc, nb
    end

    # Cree un noeud source, donc sans canal d'entree.  Ce noeud va
    # produire, sur son canal de sortie, une serie d'elements
    # provenant de l'objet source, qui peut etre n'importe quel objet
    # pouvant repondre au message #each, sinon au message #each_char,
    # sinon etre un nom de fichier. Dans ce dernier cas, ce sont les
    # lignes du fichier qui seront emises, l'une apres l'autre, sur le
    # canal de sortie.
    #
    # @param [#each, String] source La source qui fournira les elements a emettre sur le canal de sortie
    # @param [nil, :string, :filename] source_kind La sorte de source
    # @return [Pipeline] Un noeud pouvant etre utilise (seulement) comme premier etage d'un pipeline
    #
    # @note Si un objet repondant au message :each est est fourni en
    #    argument, alors ce sont les elements enumeres par :each qui
    #    seront emis sur le canal de sortie. Si une chaine est fournie
    #    et qu'aucun argument n'est specifie pour source_kind, alors
    #    ce sont les caracteres de la chaine qui sont emis sur le
    #    canal de sortie. Par contre, si une chaine est fournie et que
    #    l'argument :filename est specifie pour source_kind, alors ce
    #    sont les *lignes du fichier* qui sont emises sur le canal de
    #    sortie.  De plus, dans le cas d'un fichier: i) une exception
    #    sera lancee si aucun fichier avec le nom indique n'existe;
    #    ii) les lignes emises contiendront le saut de ligne final.
    #
    # @ensure self.source?
    #
    def self.source( source, source_kind = nil )
      # @!visibility private
      def self.body_each( source )
        lambda do |_cin, cout|
          source.each { |v| cout << v }
          cout.close
          nil
        end
      end

      # @!visibility private
      def self.body_filename( source )
        lambda do |_cin, cout|
          File.open( source, 'r' ) do |f|
            f.each_line { |line| cout << line }
            cout.close
          end

          nil
        end
      end

      # @!visibility private
      def self.body_string( source )
        lambda do |_cin, cout|
          source.each_char { |v| cout << v }
          cout.close
          nil
        end
      end

      DBC.check_value( source_kind,
                       [nil, :string, :file_name, :filename],
                       "*** Les seules sortes acceptees sont :file_name et :string" )

      if source.respond_to? :each
        gen_body = :body_each
      elsif source.respond_to? :each_char
        if [:file_name, :filename].include? source_kind
          gen_body = :body_filename
        else
          gen_body = :body_string
        end
      end
      DBC.require( gen_body,
                   "*** La source doit repondre au message :each, :each_char ou etre un nom de fichier" )

      body = self.send gen_body, source
      ProcNode.new body, :source
    end

    # Cree un noeud puits (sink), donc sans canal de sortie.  Plus
    # precisement, ce noeud va recevoir sur son canal d'entree une
    # serie d'elements, mais n'emettra aucun element sur son canal de
    # sortie.  Par contre, les objets recus pourront etre mis soit
    # dans un tableau, soit dans un fichier, selon l'argument fourni.
    #
    # @param [Array,String] sink Le puits, i.e., la destination des elements
    # @return [Pipeline] Un noeud pouvant etre utilise (seulement) comme dernier etage d'un pipeline
    # @ensure si sink.class == Array alors les elements recus sur le canal d'entree seront ajoutes au tableau sink
    # @ensure si sink.class == String alors les elements recus sur le canal d'entree seront ajoutes au fichier dont le nom est sink
    # @ensure self.sink?
    #
    def self.sink( sink )
      # @!visibility private
      def self.body_array( sink )
        lambda do |cin, _cout|
          cin.each { |v| sink << v }
          nil
        end
      end

      # @!visibility private
      def self.body_filename( sink )
        lambda do |cin, _cout|
          File.open( sink, 'w+' ) do |f|
            cin.each { |v| f.puts v }
          end

          nil
        end
      end

      DBC.check_type( sink,
                      [String, Array],
                      "*** Le sink doit etre un tableau ou un nom de fichier" )

      gen_body = sink.class == Array ? :body_array : :body_filename

      body = send gen_body, sink

      ProcNode.new body, :sink
    end
  end

end
