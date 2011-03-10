class Blitz
class Command
class Curl < Command
    def cmd_help argv
        help
    end

    def cmd_run argv
        args = parse_cli argv
        if args['help']
            return help
        end

        if not args['pattern']
            sprint args
            return
        else
            rush args
        end
    end
    
    alias_method :cmd_default, :cmd_run

    private
    def authorize_error e
        base_url = "#{e.scheme}://#{e.host}:#{e.port}"
        puts
        error "You haven't verified that you are the devops dude for #{e.host}. Make"
        error "sure the following URL is reachable and returns the string '42'."
        error ""
        error "#{base_url}/#{e.uuid}"
        error ""
        error "If your app is RESTfully built with sinatra or rails, simply add this route:"
        error ""
        error "get '/#{e.uuid}' do"
        error "    '42'"
        error "end"
        error ""
        error "Once this is done, you can blitz #{e.host} all you want."
        puts
    end

    def sprint args
        begin
            job = ::Blitz::Curl::Sprint.execute args
            result = job.result
            print_sprint_result args, result
        rescue ::Blitz::Curl::Error::Authorize => e
            authorize_error e
        rescue ::Blitz::Curl::Error::Region => e
            error "#{e.region}: #{e.message}"
        rescue ::Blitz::Curl::Error => e
            error e.message
        end
    end

    def print_sprint_result args, result
        rtt = result.duration
		if rtt < 1.0
			rtt = (rtt * 1000).floor.to_s + ' ms';
		else
			rtt = ("%.2f" % rtt) + ' sec';
		end

		puts "-" * 70
        msg "#{result.region}: Response time of #{rtt}"
        unless args['dump-header'] or args['verbose']
            msg "Try --verbose to see the request/response headers"
        end
        puts "-" * 70
        puts

        if args['dump-header'] or args['verbose']
            puts "> " + result.request.line
            result.request.headers.each_pair { |k, v| puts "> #{k}: #{v}\r\n" }
            puts
        
            content = result.request.content
            if not content.empty?
                if /^[[:print:]]+$/ =~ content
                    puts content
                else
                    puts Hexy.new(content).to_s
                end
                puts
            end
        
            puts "< " + result.response.line
            result.response.headers.each_pair { |k, v| puts "> #{k}: #{v}\r\n" }
            puts
        end
        
        content = result.response.content
        if not content.empty?
            if /^[[:print:]]+$/ =~ content
                puts content
            else
                puts Hexy.new(content).to_s
            end
        end
    end

    def rush args
        continue = true
        begin
            [ 'INT', 'STOP', 'HUP' ].each do |s| 
                trap(s) { continue = false }
            end
            job = ::Blitz::Curl::Rush.execute args
            msg "rushing from #{job.region}..."
            job.result do |result|
                print_rush_result result
                sleep 1.0 if not continue
                continue
            end
            puts
            msg "[aborted]" if not continue
        rescue ::Blitz::Curl::Error::Authorize => e
            authorize_error e
        rescue ::Blitz::Curl::Error::Region => e
            error "#{e.region}: #{e.message}"
        rescue ::Blitz::Curl::Error => e
            error e.message
        end
    end
    
    def print_rush_result result
        recent = result.timeline[-1]
        hits = "%u hits" % recent.hits
        errors = recent.errors ? ", %u errors" % recent.errors : ''
        timeouts = recent.timeouts ? ", %u timeouts" % recent.timeouts : ''
        bandwidth = ''
        if result.timeline.size > 1
            last = result.timeline[-2]
            elapsed = recent.timestamp - last.timestamp
            bps = (recent.rxbytes + recent.txbytes) - (last.rxbytes + last.txbytes)/elapsed
            bandwidth = " - %.2f bytes/sec" % bps
        else
            bps = (recent.rxbytes + recent.txbytes)/recent.timestamp
            bandwidth = " - %.2f bytes/sec" % bps
        end
        duration = recent.duration >= 0 ? " @ %.2f sec" % recent.duration : ''
        $stdout.print "#{hits}#{errors}#{timeouts}#{bandwidth}#{duration}\n"
        $stdout.flush
    end

    def help
        helps = [
            { :short => '-A', :long => '--user-agent', :value => '<string>', :help => 'User-Agent to send to server' },
            { :short => '-b', :long => '--cookie', :value => 'name=<string>', :help => 'Cookie to send to the server (multiple)' },
            { :short => '-d', :long => '--data', :value => '<string>', :help => 'Data to send in a PUT or POST request' },
            { :short => '-D', :long => '--dump-header', :value => '<file>', :help => 'Print the request/response headers' },
            { :short => '-e', :long => '--referer', :value => '<string>', :help => 'Referer URL' },
            { :short => '-h', :long => '--help', :value => '', :help => 'Help on command line options' },
            { :short => '-H', :long => '--header', :value => '<string>', :help => 'Custom header to pass to server' },
            { :short => '-p', :long => '--pattern', :value => '<s>-<e>:<d>', :help => 'Ramp from s to e concurrent requests in d secs' },
            { :short => '-r', :long => '--region', :value => '<string>', :help => 'california|virginia|singapore|ireland|japan' },
            { :short => '-s', :long => '--status', :value => '<number>', :help => 'Assert on the HTTP response status code' },
            { :short => '-T', :long => '--timeout', :value => '<ms>', :help => 'Wait time for both connect and responses' },
            { :short => '-u', :long => '--user', :value => '<user[:pass]>', :help => 'User and password for authentication' },
            { :short => '-X', :long => '--request', :value => '<string>', :help => 'Request method to use (GET, HEAD, PUT, etc.)' },
            { :short => '-v', :long => '--verbose', :value => '', :help => 'Print the request/response headers' },
            { :short => '-1', :long => '--tlsv1', :value => '', :help => 'Use TLSv1 (SSL)' },
            { :short => '-2', :long => '--sslv2', :value => '', :help => 'Use SSLv2 (SSL)' },
            { :short => '-3', :long => '--sslv3', :value => '', :help => 'Use SSLv3 (SSL)' }
        ]

        max_long_size = helps.inject(0) { |memo, obj| [ obj[:long].size, memo ].max }
        max_value_size = helps.inject(0) { |memo, obj| [ obj[:value].size, memo ].max }
        puts
        msg "Usage: blitz curl <options> <url>"
        puts
        helps.each do |h|
            msg "%-*s %*s %-*s %s" % [max_long_size, h[:long], 2, h[:short], max_value_size, h[:value], h[:help]]
        end
        puts
    end

    def parse_cli argv
        hash = Hash.new
        while not argv.empty?
            break if argv.first[0,1] != '-'

            k = argv.shift
            if [ '-A', '--user-agent' ].member? k
                hash['user-agent'] = shift(k, argv)
                next
            end

            if [ '-b', '--cookie' ].member? k
                # TODO: support cookie jars
                hash['cookies'] ||= []
                hash['cookies'] << shift(k, argv)
                next
            end

            if [ '-d', '--data' ].member? k
                hash['content'] ||= Hash.new
                hash['content']['data'] ||= []
                v = shift(k, argv)
                v = File.read v[1..-1] if v =~ /^@/
                hash['content']['data'] << v
                next
            end

            if [ '-D', '--dump-header' ].member? k
                hash['dump-header'] = shift(k, argv)
                next
            end

            if [ '-e', '--referer'].member? k
                hash['referer'] = shift(k, argv)
                next
            end

            if [ '-h', '--help' ].member? k
                hash['help'] = true
                next
            end

            if [ '-H', '--header' ].member? k
                hash['headers'] ||= []
                hash['headers'].push shift(k, argv)
                next
            end

            if [ '-p', '--pattern' ].member? k
                v = shift(k, argv)
                if not /^(\d+)-(\d+):(\d+)$/ =~ v
                    raise Test::Unit::AssertionFailedError, "invalid ramp pattern"
                end
                hash['pattern'] = {
                    'iterations' => 1,
                    'intervals' => [{
                        'iterations' => 1,
                        'start' => $1.to_i,
                        'end' => $2.to_i,
                        'duration' => $3.to_i
                    }]
                }
                next
            end

            if [ '-r', '--region' ].member? k
                v = shift(k, argv)
                assert_match(/^california|virginia|singapore|ireland|japan$/, v, 'region must be one of california, virginia, singapore, japan or ireland')
                hash['region'] = v
                next
            end

            if [ '-s', '--status' ].member? k
                hash['status'] = shift(k, argv).to_i
                next
            end

            if [ '-T', '--timeout' ].member? k
                hash['timeout'] = shift(k, argv).to_i
                next
            end

            if [ '-u', '--user' ].member? k
                hash['user'] = shift(k, argv)
                next
            end

            if [ '-X', '--request' ].member? k
                hash['request'] = shift(k, argv)
                next
            end
            
            if [ '-v', '--verbose' ].member? k
                hash['verbose'] = true
                next
            end

            if [ '-1', '--tlsv1' ].member? k
                hash['ssl'] = 'tlsv1'
                next
            end

            if [ '-2', '--sslv2' ].member? k
                hash['ssl'] = 'sslv2'
                next
            end

            if [ '-3', '--sslv3' ].member? k
                hash['ssl'] = 'sslv2'
                next
            end

            raise ArgumentError, "Unknown option #{k}"
        end

        if not hash['help']
            url = argv.shift
            assert_not_nil(url, 'no URL specified!')
            hash['url'] = url
        end
        
        if hash.member? 'content'
            data_size = hash['content']['data'].inject(0) { |m, v| m + v.size }
            assert(data_size < 10*1024, "POST content must be < 10K")
        end

        hash
    end

    def shift key, argv
        val = argv.shift
        assert_not_nil(val, "missing value for #{key}")
        val
    end
end # Curl
end # Command
end # Blitz
