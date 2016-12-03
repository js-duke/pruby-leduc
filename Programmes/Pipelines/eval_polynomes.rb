$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

#
# Evaluation simple et directe, pour verifier les resultats des tests.
#
def eval_polynome( x, coeffs )
  coeffs
    .each_index
    .reduce(0) { |somme, i| somme + coeffs[i] * x**i }
end


#
# VERSION avec parallelisme de donnees.
#
def eval_polynomes_pmap( xs, coeffs )
  xs.pmap { |x| eval_polynome( x, coeffs ) }
end

def eval_polynomes_pcall( xs, coeffs )
  res = Array.new( xs.size )

  PRuby.pcall (0...xs.size),
  ->( k ) { res[k] = eval_polynome( xs[k], coeffs ) }

  res
end

def eval_polynomes_future( xs, coeffs )
  res = xs.map do |x|
    PRuby.future { eval_polynome( x, coeffs ) }
  end

  res.map( &:value )
end


#
# VERSION avec pipeline.
#
def pipeline_coeffs( coefficients )
  les_lambdas = coefficients.reverse.map do |coeff|
    lambda do |cin, cout|
      cin.each { |x, y| cout << [x, y * x + coeff] }
      cout.close
    end
  end
  PRuby.pipeline( *les_lambdas )
end

def eval_polynomes( xs, coeffs )
  init = lambda do |cin, cout|
    cin.each { |v| cout << [v, 0] }
    cout.close
  end

  fetch_result = lambda do |cin, cout|
    cin.each { |v| cout << v.last }
    cout.close
  end

  results = []

  ( PRuby.pipeline_source(xs) \
    >>
    (init | pipeline_coeffs(coeffs) | fetch_result) \
    >>
    PRuby.pipeline_sink(results)
    )
    .run

  results
end
