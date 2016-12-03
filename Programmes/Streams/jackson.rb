$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

#@@@/jackson_fastflow/transformer_jackson/
def jackson_fastflow( fich_donnees, fich_sortie, n )
  # Transforme flux de lignes en flux de caracteres.
  depaqueter = lambda { |ligne| ligne.chars.to_a }

  changer_exposant = lambda do |precedent, c|
    if precedent == '*' && c == '*'
      ['^', PRuby::GO_ON]
    else
      [c, precedent ? precedent : PRuby::GO_ON]
    end
  end

  # Transforme flux de cars en flux de lignes de longueur n.
  n = 4
  paqueter = lambda do |bloc, c|
    bloc << c
    if bloc.size == n
      ['', bloc]
    else
      [bloc, PRuby::GO_ON]
    end
  end

  PRuby::Stream.source( fich_donnees )
    .flat_map( &depaqueter )
    .fastflow( stateful: true,
               at_eos: -> char { char },
               &changer_exposant )
    .fastflow( stateful: '',
               at_eos: -> bloc { bloc },
               &paqueter )
    .sink( fich_sortie )
end
#@@@

#@@@/jackson_stateful/transformer_jackson/
def jackson_stateful( fich_donnees, fich_sortie, n )
  # Transforme flux de lignes en flux de caracteres.
  depaqueter = lambda do |ligne|
    ligne.chars.to_a
  end

  changer_exposant = lambda do |precedent, c|
    if precedent == '*' && c == '*'
      [nil, '^']
    else
      [c, precedent]
    end
  end

  # Transforme flux de cars en flux de lignes de longueur n.
  paqueter = lambda do |bloc, c|
    bloc << c
    if bloc.size == n
      ['', bloc]
    else
      [bloc, nil]
    end
  end

  PRuby::Stream.source( fich_donnees )
    .flat_map( &depaqueter )
    .stateful( at_eos: :STATE, &changer_exposant )
    .stateful( initial_state: '', at_eos: :STATE,  &paqueter )
    .sink( fich_sortie )
end
#@@@

def jackson_( input_file, output_file, n )
  # Transform a stream of lines into a stream of characters.
  unpack = lambda do |line|
    line.chars.to_a
  end

  # Transform ** into ^.
  change_exponent = lambda do |preceding, c|
    if preceding == '*' && c == '*'
      [nil, '^']
    else
      [c, preceding]
    end
  end

  # Transform a stream of chars into a stream of lines of size n.
  pack = lambda do |block, c|
    block << c
    if block.size == n
      ['', block]
    else
      [block, nil]
    end
  end

  PRuby::Stream.source( input_file )
    .flat_map( &unpack )
    .stateful( at_eos: :EMIT_STATE, &change_exponent )
    .stateful( initial_state: '', at_eos: :EMIT_STATE,  &pack )
    .sink( output_file )
end
