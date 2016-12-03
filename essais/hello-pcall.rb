require 'system'
require 'pruby'

nb_threads = ARGV[0] ? ARGV[0].to_i : System::CPU.count


PRuby.pcall (0...nb_threads), lambda { |num_thread| puts "Hello world de thread #{num_thread}" }

puts "--"

PRuby.pcall (0...nb_threads), -> num_thread { puts "Hello world de thread #{num_thread}" }

puts "--"

PRuby.pcall (0...nb_threads), ->(num_thread) { puts "Hello world de thread #{num_thread}" }


=begin

Exemple de resultat: a discuter et expliquer!!a


$ ruby essais/hello-thread.rb 20
Hello world de thread 0
Hello world de thread 1
Hello world de thread 2
Hello world de thread 3
Hello world de thread 4
Hello world de thread 5
Hello world de thread 6
Hello world de thread 7
Hello world de thread 8
Hello world de thread 9
Hello world de thread 10
Hello world de thread 11
Hello world de thread 12
Hello world de thread 13
Hello world de thread 14
Hello world de thread 15Hello world de thread 16

Hello world de thread 17
Hello world de thread 18
Hello world de thread 19

=end
