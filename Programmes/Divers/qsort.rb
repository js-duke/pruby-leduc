$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

module QSort
  def trier_selection( a, inf, sup )
    (inf..sup).each do |i|
      min = i
      ((i+1)..sup).each do |j|
        min = j if a[j] < a[min]
      end
      a[i], a[min] = a[min], a[i]
    end
  end


  def partitionner( a, inf, sup, &trouver_pivot )
    # PRECONDITION
    #   inf < sup
    # POSTCONDITION
    #   a est une permutation de a',
    #   inf <= pos_pivot <= sup,
    #   ALL( inf      <= i <= pos_pivot :: a[i]         <= a[pos_pivot] ),
    #   ALL( pos_pivot<  i <= sup       :: a[pos_pivot] <  a[i]         )
    # ARGUMENT
    #   bloc = strategie pour selectionner le pivot et sa position associee.

    pivot, pos_pivot = trouver_pivot.call( a, inf, sup )

    # On le met au debut du tableau pour, petit a petit, trouver sa bonne position.
    a[inf], a[pos_pivot] = a[pos_pivot], a[inf]
    pos_pivot = inf

    ((inf+1)..sup).each do |i|
      if a[i] <= pivot
        pos_pivot += 1
        a[i], a[pos_pivot] = a[pos_pivot], a[i] # Interchange deux elements.
      end
    end

    # Finalement, on deplace le pivot a sa bonne position.
    a[inf], a[pos_pivot] = a[pos_pivot], a[inf]

    pos_pivot
  end

  def qsort_seq( a, inf, sup )
    return if inf >= sup # Cas de base: rien a faire car deja trie!

    # Cas recursifs.
    # On partitionne a en deux parties:
    # - Gauche: plus petit ou egal au pivot.
    # - droite: plus grand ou egal au pivot.
    pos_pivot = partitionner( a, inf, sup ) { |a, inf, _sup| [a[inf], inf] }

    # On trie recursivement.
    qsort_seq( a, inf, pos_pivot - 1 )
    qsort_seq( a, pos_pivot + 1, sup )
  end

  def qsort_par( a, inf, sup )
    return if inf >= sup

    pos_pivot = partitionner( a, inf, sup ) { |a, inf, _sup| [a[inf], inf] }

    PRuby.pcall\
    -> { qsort_par( a, inf, pos_pivot - 1 ) },
    -> { qsort_par( a, pos_pivot+1, sup ) }
  end


  def pivot_mediane( a, inf, sup )
    def en_ordre?( a, p1, p2, p3 ); a[p1] <= a[p2] && a[p2] <= a[p3]; end

    p1, p2, p3 = inf, (inf + sup) / 2, sup

    pos_pivot = if en_ordre?( a, p1, p2, p3 )
                  p2
                elsif en_ordre?( a, p1, p3, p2 )
                  p3
                elsif en_ordre?( a, p2, p1, p3 )
                  p1
                elsif en_ordre?( a, p2, p3, p1 )
                  p3
                elsif en_ordre?( a, p3, p2, p1 )
                  p2
                elsif en_ordre?( a, p3, p1, p2 )
                  p1
                end

    [a[pos_pivot], pos_pivot]
  end

  def qsort_par2( a, inf, sup, seuil = 10 )
    # Cas de base "simple" => tri (quadratique) par selection.
    return trier_selection( a, inf, sup ) if (sup - inf) <= seuil

    # Cas recursifs: on choisit comme pivot une approximation de la mediane.
    pos_pivot = partitionner( a, inf, sup ) { |a, inf, sup| pivot_mediane(a, inf, sup) }

    PRuby.pcall\
    -> { qsort_par2( a, inf, pos_pivot-1 ) },
    -> { qsort_par2( a, pos_pivot+1, sup ) }
  end
end
