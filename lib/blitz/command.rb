require 'test/unit/assertions'

# The default template string contains what was sent and received. Strip 
# these out since we don't need them
unless RUBY_VERSION =~ /^1.9/
    class Test::Unit::Assertions::AssertionMessage
        alias :old_template :template

        def template
            @template_string = ''
            @parameters = []
            old_template
        end
    end
else
    module ::Test::Unit
        AssertionFailedError = MiniTest::Assertion
    end
end

class Blitz
class Command
    include Test::Unit::Assertions
    include Helper
end
end # Blitz

Dir["#{File.dirname(__FILE__)}/command/*.rb"].each { |c| require c }
