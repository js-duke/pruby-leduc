$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

def depaqueter
  lambda do |cin, cout|
    cin.each do |ligne|
      ligne.each_char { |c| cout << c }
    end
    cout.close
  end
end

def paqueter( n )
  lambda do |cin, cout|
    ligne = ''
    cin.each do |c|
      ligne << c
      if ligne.size == n
        cout << ligne
        ligne = ''
      end
    end
    cout << ligne unless ligne.empty?
    cout.close
  end
end

def traiter_flux( n, donnees )
  changer_exposant = lambda do |cin, cout|
    precedent = nil
    cin.each do |c|
      if precedent == '*' && c == '*'
        precedent, c = '^', nil
      end
      cout << precedent if precedent
      precedent = c
    end
    cout << precedent if precedent
    cout.close
  end

  r = []

  (PRuby.pipeline_source(donnees) |
   depaqueter |
   changer_exposant |
   paqueter(n) |
   PRuby.pipeline_sink(r))
    .run

  r
end

def traiter_flux_peek( n, donnees )
  changer_exposant_peek = lambda do |cin, cout|
    cin.each do |c|
      if c == '*' && cin.peek == '*'
        cin.get
        c = '^'
      end
      cout << c
    end
    cout.close
  end

  r = []

  (PRuby.pipeline_source(donnees) |
   depaqueter |
   changer_exposant_peek |
   paqueter(n) |
   PRuby.pipeline_sink(r))
    .run

  r
end

def traiter_flux_lambda_var( n, donnees )

  def traiter_jackson( n2 )
    depaqueter = lambda do |cin, cout|
      cin.each do |ligne|
        ligne.each_char do |c|
          cout << c
        end
      end
      cout.close
    end

    paqueter = lambda do |cin, cout|
      ligne = ''
      cin.each do |c|
        ligne << c
        if ligne.size == n2
          cout << ligne
          ligne = ''
        end
      end
      cout << ligne unless ligne.empty?
      cout.close
    end

    changer_exposant = lambda do |cin, cout|
      cin.each do |c|
        (c = '^'; cin.get) if c == '*' && cin.peek == '*'
        cout << c
      end
      cout.close
    end

    depaqueter | changer_exposant | paqueter
  end

  r = []

  (PRuby.pipeline_source(donnees) |
   traiter_jackson( n ) |
   PRuby.pipeline_sink(r))
    .run

  r
end
