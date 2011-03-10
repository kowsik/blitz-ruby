class Blitz
module Helper
    def error msg
        $stderr.puts "!! #{msg}"
    end
    
    def msg msg
        puts msg
    end
    
    def ask
        gets.strip
    end
end
end # Blitz
