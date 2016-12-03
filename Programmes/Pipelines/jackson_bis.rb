$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

#@@@/jackson/transformer_jackson/
def jackson( fich_donnees, fich_sortie, n )
  # Transforme flux de lignes en flux de caracteres.
  depaqueter = lambda do |cin, cout|
    cin.each do |ligne|
      ligne.each_char { |c| cout << c }
    end
    cout.close
  end

  changer_exposant = lambda do |cin, cout|
    cin.each do |c|
      (cin.get; c = "^") if c == "*" && cin.peek == "*"
      cout << c
    end
    cout.close
  end

  # Transforme flux de cars en flux de lignes de longueur n.
  paqueter = lambda do |cin, cout|
    ligne = ""
    cin.each do |char|
      ligne << char
      (cout << ligne; ligne = "") if ligne.size == n
    end

    cout << ligne unless ligne.empty?
    cout.close
  end

  (PRuby.pipeline_source(fich_donnees) |
   depaqueter |
   changer_exposant |
   paqueter |
   PRuby.pipeline_sink(fich_sortie)).
    run
end
#@@@
