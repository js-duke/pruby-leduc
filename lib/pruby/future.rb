module PRuby

  # Class auxiliaire, privee, utilisee pour les ForkJoin::Task de la
  # bibliotheque jruby/Java lors de la creation de future.
  #
  class PRubyFuture < ForkJoin::Task
    # Nouvelle tache encapsulant un future.
    # @param [Proc] expr L'expression a evaluer
    #
    def initialize( expr )
      @expr = expr
    end

    # Appel effectif de l'expression
    # @return [void]
    #
    def call
      @r = @expr.call
    end

    # Obtention, bloquante, de la valeur associee au future
    # @return La valeur finale de l'expression
    def value
      join
      @r
    end
  end

end
