class Blitz
module Curl 
class Sprint
    class Request
        attr_reader :line
        attr_reader :method
        attr_reader :url
        attr_reader :headers
        attr_reader :content
        
        def initialize json
            @line = json['line']
            @method = json['method']
            @url = json['url']
            @content = json['content'].unpack('m')[0]
            @headers = json['headers']
        end
    end
    
    class Response
        attr_reader :line
        attr_reader :status
        attr_reader :message
        attr_reader :headers
        attr_reader :content
        
        def initialize json
            @line = json['line']
            @status = json['status']
            @message = json['message']
            @content = json['content'].unpack('m')[0]
            @headers = json['headers']
        end        
    end
    
    class Result
        attr_reader :region
        attr_reader :duration
        attr_reader :connect
        attr_reader :request
        attr_reader :response
        
        def initialize json
            result = json['result']
            @region = result['region']
            @duration = result['duration']
            @connect = result['connect']
            @request = Request.new result['request']
            @response = Response.new result['response']
        end        
    end
    
    def self.execute args
        args.delete 'pattern'

        res = Command::API.client.curl_execute args
        raise Error.new(res) if res['error']
        return self.new res['job_id']
    end
    
    attr_reader :job_id
    
    def initialize job_id
        @job_id = job_id
    end
    
    def result
        while true
            sleep 2.0

            job = Command::API.client.job_status job_id
            if job['error']
                raise Error
            end

            result = job['result']
            next if job['status'] == 'queued'
            next if job['status'] == 'running' and not result

            raise Error if not result

            error = result['error']
            if error
                if error == 'dns'
                    raise Error::DNS.new(result)
                elsif error == 'connect'
                    raise Error::Connect.new(result)
                elsif error == 'timeout'
                    raise Error::Timeout.new(result)
                elsif error == 'parse'
                    raise Error::Parse.new(result)
                elsif result['assert'] == 0
                    raise Error::Status.new(result)
                else
                    raise Error
                end
            end
            
            return Result.new(job)
        end
    end
    
    def abort
        Command::API.client.abort_job job_id rescue nil
    end    
end
end # Curl
end # Blitz
