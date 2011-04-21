require 'test/unit/assertions'

# The default template string contains what was sent and received. Strip 
# these out since we don't need them
unless RUBY_VERSION =~ /^1.9/
    module Test # :nodoc:
        module Unit # :nodoc:
            module Assertions # :nodoc:
                class AssertionMessage # :nodoc:
                    alias :old_template :template

                    def template
                        @template_string = ''
                        @parameters = []
                        old_template
                    end
                end
            end
        end
    end
else
    module ::Test::Unit # :nodoc:
        AssertionFailedError = MiniTest::Assertion
    end
end

class Blitz
class Command # :nodoc:
    include Test::Unit::Assertions
    include Helper
end
end # Blitz

Dir["#{File.dirname(__FILE__)}/command/*.rb"].each { |c| require c }
