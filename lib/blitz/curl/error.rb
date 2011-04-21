class Blitz
module Curl
class Error < StandardError # :nodoc:
    def initialize json={}
        super json['reason'] || "Hmmm, something went wrong. Try again in a little bit?"
    end
    
    # This exception is raised when you haven't authorized a rush against your app
    class Authorize < Error
        # The scheme used in the rush (http or httpss)
        attr_reader :scheme
        
        # The host in the URL
        attr_reader :host
        
        # The port (if specified) in the URL
        attr_reader :port
        
        # The unique ID to use a URL path in your app for authorization to succeed
        attr_reader :uuid

        def initialize json
            @scheme = json['scheme']
            @host   = json['host']
            @port   = json['port']
            @uuid   = json['uuid']
            super
        end
    end
    
    # The base class for all exceptions thrown by the distributed scale engines
    class Region < Error
        # The region from which the test was run
        attr_reader :region
        
        def initialize json # :nodoc:
            @region = json['region']
            super
        end
    end
    
    # This exception is raised when the DNS resolution fails
    class DNS < Region
    end
    
    # This exception is raised when the connection to your app fails
    class Connect < Region
    end
    
    # This exception is raised when the connection or the response times out
    class Timeout < Region
    end

    # This exception is raised when the arguments to sprint or rush is invalid
    class Parse < Region
    end
    
    # This exception is raised when you have an explicit status code check and
    # the assertion fails
    class Status < Region
    end
end
end # Curl
end # Blitz
