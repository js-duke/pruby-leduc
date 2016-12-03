$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

NB_FOIS = 20

def num_bucket( mot, nb_buckets )
  n = nil
  NB_FOIS.times do
    n = mot.size
    while n >= nb_buckets
      n -= 1
    end
  end

  mot.size % nb_buckets
end

def histogramme_seq( mots, nb_buckets )
  histogramme = Array.new(nb_buckets) { 0 }

  mots.each do |mot|
    ind = num_bucket(mot, nb_buckets)
    histogramme[ind] += 1
  end

  histogramme
end

def histogramme_par_donnees_sans_mutex( mots, nb_buckets )
  histogramme = Array.new(nb_buckets) { 0 }

  mots.peach do |mot|
    ind = num_bucket(mot, nb_buckets)
    histogramme[ind] += 1
  end

  histogramme
end

def histogramme_par_donnees_avec_mutex( mots, nb_buckets )
  histogramme = Array.new(nb_buckets) { 0 }
  mutexs = Array.new(nb_buckets) { Mutex.new }

  mots.peach do |mot|
    ind = num_bucket(mot, nb_buckets)
    mutexs[ind].synchronize {
      histogramme[ind] += 1
    }
  end

  histogramme
end

def histogramme_par_donnees( mots, nb_buckets )
  histogrammes = Array.new(PRuby.nb_threads) { Array.new(nb_buckets) { 0 } }

  mots.peach do |mot|
    ind = num_bucket(mot, nb_buckets)
    histogrammes[PRuby.thread_index][ind] += 1
  end

  histogramme = Array.new(nb_buckets) { 0 }
  histogramme.each_index do |k|
    histogrammes.each do |histo|
      histogramme[k] += histo[k]
    end
  end

  histogramme
end

def histogramme_par_resultat( mots, nb_buckets )
  histogramme = Array.new(nb_buckets) { 0 }

  histogramme.peach_index do |ind|
    mots.each do |mot|
      histogramme[ind] += 1 if num_bucket(mot, nb_buckets) == ind
    end
  end

  histogramme
end
