############################################################
#
# Quelques methodes ajoutees a la classe Proc, donc avec "monkey
# patch", pour permettre la creation de pipelines et de fermes
# (farms), et ce directement a partir d'un objet de classe Proc
# (lambda, fonction anonyme).
#
# Il s'agit donc une forme de conversion implicite d'une lambda en un
# pipeline.
#
############################################################

class Proc

  # Un Proc qui recoit ce message est implicitement transforme en un
  # premier etage de pipeline, ou le 2e etage est l'autre argument
  # (other).
  #
  # @param [Proc, Pipeline] other Autre objet a utiliser comme 2e etage du pipeline a creer
  # @return [PRuby::Pipeline] Un pipeline avec self comme 1er etage et other comme 2e etage
  #
  def |( other )
    (PRuby.pipeline self).add_stage( other )
  end

  def &( other )
    (PRuby.pipeline self).add_stage( other )
  end

  # Un Proc qui recoit ce message est implicitement utilise comme une
  # ferme ayant le nombre indique de travailleurs.
  #
  # @param [Fixnum] nb Nombre d'instances de travailleur requis
  # @return [PRuby::Pipeline] Une ferme avec nb instances, qui peut etre utilisee ensuite dans un pipeline, ou chaque travailleur execute self
  #
  def *( nb )
    PRuby::PipelineFactory.farm self, nb
  end

  # Lance l'execution d'une lambda dans un Thread indepdendant, lambda
  # qui utilise une serie de canaux de communication (Channel) pour
  # interagir avec d'autres processus.
  #
  # Plus specifiquement, la methode vise a emuler la facon utilisee en
  # go pour lancer l'execution d'une goroutine, et ce en utilisant les
  # methodes appropriees definies dans la classe Channel:
  #
  #  - Go:
  #     func p1( cin chan int, cout chan int ) {
  #       n <- cin
  #       cout <- 2 * n + 1
  #       close( cout )
  #     }
  #     go p1( c0, c1 )
  #     c0 <- 10
  #     <- c1 # Retourne 21
  #
  #  - PRuby
  #     p1 = lambda do |cin, cout|
  #       n = cin.get
  #       cout << 2 * n + 1
  #       cout.close
  #     end
  #     p1.go( c0, c1 )
  #     c0 << 10
  #     c1.get # Retourne 21
  #
  # @param [Array<Channel>] canaux Les canaux de communication a utiliser
  # @return [Thread] Un Thread, sur lequel on peut faire join si on desire attendre la terminaison
  #
  def go( *canaux )
    Thread.new { call *canaux }
  end
end
