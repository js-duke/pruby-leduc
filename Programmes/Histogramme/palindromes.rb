$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

def est_palindrome( mot )
  m = mot.upcase
  m == m.reverse
end

def indice( mot, nb_buckets )
  (mot[0].upcase.ord - 'A'.ord) % nb_buckets
end

def trouver_palindromes_seq( mots, nb_buckets )
  palindromes = Array.new( nb_buckets ) { [] }

  mots.each do |mot|
    if est_palindrome( mot )
      palindromes[ indice(mot, nb_buckets) ] << mot
    end
  end

  palindromes
end

def trouver_palindromes_par_donnees_sans_mutex( mots, nb_buckets )
  palindromes = Array.new( nb_buckets ) { [] }

  mots.peach do |mot|
    if est_palindrome( mot )
      ind = indice(mot, nb_buckets)
      palindromes[ ind ] << mot
    end
  end
  palindromes
end

def trouver_palindromes_par_donnees( mots, nb_buckets )
  palindromes = Array.new( nb_buckets ) { [] }
  mutexs = Array.new( nb_buckets ) { Mutex.new }

  mots.peach do |mot|
    if est_palindrome( mot )
      ind = indice(mot, nb_buckets)
      mutexs[ind].lock
      palindromes[ ind ] << mot
      mutexs[ind].unlock
    end
  end
  palindromes
end

def trouver_palindromes_par_resultat( mots, nb_buckets )
  palindromes = Array.new( nb_buckets ) { [] }

  palindromes.peach_index do |ind|
    mots.each do |mot|
      if indice(mot, nb_buckets) == ind && est_palindrome( mot )
        palindromes[ ind ] << mot
      end
    end
  end

  palindromes
end
