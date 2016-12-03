$LOAD_PATH.unshift('~/pruby/lib')
require 'pruby'

def jackson( input_file, output_file, n )
  unpack = lambda do |cin, cout|
    cin.each do |line|
      line.each_char { |c| cout << c }
    end
    cout.close
  end

  change_exponent = lambda do |cin, cout|
    cin.each do |c|
      (cin.get; c = "^") if c == "*" && cin.peek == "*"
      cout << c
    end
    cout.close
  end

  pack = lambda do |cin, cout|
    line = ""
    cin.each do |char|
      line << char
      (cout << line; line = "") if line.size == n
    end

    cout << line unless line.empty?
    cout.close
  end

  (PRuby.pipeline_source(input_file) |
   unpack |
   change_exponent |
   pack |
   PRuby.pipeline_sink(output_file)).
    run
end
