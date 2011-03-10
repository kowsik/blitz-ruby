class Blitz
module Curl 
class Rush
    class Point
        attr_reader :timestamp
        attr_reader :duration
        attr_reader :total
        attr_reader :hits
        attr_reader :errors
        attr_reader :timeouts
        attr_reader :volume
        attr_reader :txbytes
        attr_reader :rxbytes
        
        def initialize json
            @timestamp = json['timestamp']
            @duration = json['duration']
            @total = json['total']
            @hits = json['executed']
            @errors = json['errors']
            @timeouts = json['timeouts']
            @volume = json['volume']
            @txbytes = json['txbytes']
            @rxbytes = json['rxbytes']
        end
    end
    
    class Result
        attr_reader :region
        attr_reader :timeline
        
        def initialize json
            result = json['result']
            @region = result['region']
            @timeline = result['timeline'].map { |p| Point.new p }
        end        
    end
    
    def self.execute args
        if not args.member? 'pattern'
            raise ArgumentError, 'missing pattern'
        end

        res = Command::API.client.curl_execute args
        raise Error.new(res) if res['error']
        return self.new res
    end
    
    attr_reader :job_id
    attr_reader :region
    
    def initialize json
        @job_id = json['job_id']
        @region = json['region']
    end
    
    def result
        last = nil
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
                elsif error == 'authorize'
                    raise Error::Authorize.new(result)
                else
                    raise Error
                end
            end
            
            last = Result.new(job)
            continue = yield last rescue false
            if not continue
                abort!
                break
            end
            
            break if job['status'] == 'completed'
        end
        
        return last
    end
    
    def abort!
        Command::API.client.abort_job job_id rescue nil
    end    
end
end # Curl
end # Blitz
