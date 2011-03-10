class Blitz
module Curl
class Error < StandardError
    def initialize json={}
        super json['reason'] || "Hmmm, something went wrong. Try again in a little bit?"
    end
    
    class Authorize < Error
        attr_reader :scheme, :host, :port, :uuid

        def initialize json
            @scheme = json['scheme']
            @host   = json['host']
            @port   = json['port']
            @uuid   = json['uuid']
            super
        end
    end
    
    class Region < Error
        attr_reader :region
        
        def initialize json
            @region = json['region']
            super
        end
    end
    
    class DNS < Region
    end
    
    class Connect < Region
    end
    
    class Timeout < Region
    end

    class Parse < Region
    end
    
    class Status < Region
    end
end
end # Curl
end # Blitz
