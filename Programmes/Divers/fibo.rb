$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

#require 'memoizable'

class Fibo
  #include Memoizable

  def fibo_par( n )
    return n if [0, 1].include? n

    f1, f2 = nil, nil

    PRuby.pcall\
    lambda { f1 = fibo_par(n - 1) },
    lambda { f2 = fibo_par(n - 2) }

    f1 + f2
  end

  def fibo_seq( n )
    return n if [0, 1].include? n

    f1 = fibo_seq(n-1)
    f2 = fibo_seq(n-2)

    f1 + f2
  end

  #memoize :fibo_memo
  # Ne fonctionne pas avec memoization:

  # Memoizable::MethodBuilder::InvalidArityError: Cannot memoize
  # Fibo#fibo_memo, its arity is 1

end
