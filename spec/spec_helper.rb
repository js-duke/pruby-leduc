require 'bundler/setup'
require 'minitest/autorun'
require 'minitest/spec'

$LOAD_PATH.unshift('.', 'spec', 'lib')

if __FILE__ == $0
  Dir.glob('./spec/**/*_spec.rb') { |f| require f }
end

#
# For easily skipping some test.
#
# NOTE: I could also have used the following minitest command in the test:
#    skip("Reason for skipping test")
#
class Object
  def _describe( test )
    puts "--- Skipping tests \"#{test}\" ---"
  end

  def _it( test )
    puts "--- Skipping test \"#{test}\" ---"
  end

  def it_( test )
    puts "--- Skipping test \"#{test}\" ---"
  end

  # For making look more like RSpec.
  alias :context :describe
  alias :_context :_describe
end
