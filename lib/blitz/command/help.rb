class Blitz
class Command
class Help < Command
    def cmd_default argv
        puts
        msg "Usage: blitz <command> <options>"
        helps = [
            { :cmd => 'help', :help => "Display this help" },
            { :cmd => 'api:init', :help => 'Validate your API key' },
            { :cmd => 'curl', :help => 'Run a sprint or a rush' },
            { :cmd => 'curl:help', :help => 'Show help on sprint and rushing' },
            { :cmd => 'couch:fuzz', :help => 'Auto generate blitz tests from CouchDB' }
        ]
        
        max_cmd_size = helps.inject(0) { |memo, obj| [ obj[:cmd].size, memo ].max } + 4
        helps.each do |h|
            msg "%*s - %s" % [max_cmd_size, h[:cmd], h[:help]]
        end
        puts
    end
end
end # Command
end # Blitz
