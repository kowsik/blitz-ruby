require 'couchrest'

class Blitz
class Command
class Couch < Command
    attr_reader :urls

    def initialize
        @urls = []
    end

    def cmd_fuzz argv
        assert argv.size != 0, "need a CouchDB URL (like http://localhost:5984)"

        url = argv.shift
        database = argv.shift

        uri = URI.parse url rescue nil
        assert_not_nil uri, "Can't parse #{url} - Is it valid?"

        couch = CouchRest.new(uri)
        couch.databases.reject { |n| n[0,1] == '_' }.each do |name|
            next if database and database != name
            msg "-------------- processing #{name}... ----------------------"
            db = couch.database(name)
            designs = db.documents :startkey => "_design", :endkey => "_design0", :include_docs => true
            designs['rows'].each do |row|
                design = row['doc']

                # Ignore design documents that don't have views
                next unless design['views']
                analyze_design db, design
            end

            if urls.empty?
                error "Nothing interesting found. Sorry."
                return
            end
            
            output_urls db
            urls.clear
        end
    end

    def analyze_design db, design
        _, dname = design['_id'].split('/', 2)
        views = design['views']
        views.each_pair do |vname, view|
            analyze_view db, dname, vname, view['reduce']
        end
    end

    def analyze_view db, design, view, reduce
        msg "  analyzing #{design}/#{view}..."

        opts = {}
        opts[:group] = true if reduce
        first = db.view "#{design}/#{view}", opts.merge(:limit => 1)
        last = db.view "#{design}/#{view}", opts.merge(:limit => 1, :descending => true)

        return if first['rows'].empty?

        first_row = first['rows'][0]
        first_key = first_row['key']
        last_row = last['rows'][0]
        last_key = last_row['key']

        # Randomize the limit so it's anywhere from 1 to 10 docs maximum
        variables = { :l => 'number[1,10]' }
        query = { :limit => '#{l}' }
        if reduce
            query.merge! :group => true
        else
            variables.merge! :id => '[true,false]'
            query.merge! :include_docs => '#{id}'
        end

        case first_key
        when Array
            # If the key is an array and this view is reducing, randomize the 
            # group level to have the query server work harder
            if reduce
                variables[:gl] = 'number[1,5]'
                query[:group_level] = '#{gl}'
            end
        when Integer
            # Randomize start/end keys, but within the valid range
            variables[:sk] = "number[#{first_key},#{last_key}]"
            variables[:ek] = "number[#{first_key},#{last_key}]"
            query[:startkey] = '#{sk}'
            query[:endkey] = '#{ek}'
        when String
            # Randomize start/end keys, but within the valid range
            variables[:sk] = "alpha[4,12]"
            variables[:ek] = "alpha[4,12]"
            query[:startkey] = "%22#{first_key[0,2]}\#{sk}%22"
            query[:endkey] = "%22#{last_key[0,2]}z\#{ek}%22"
        when TrueClass, FalseClass
            variables[:sk] = "[true,false]"
            variables[:ek] = "[true,false,false,true]"
            query[:startkey] = '#{sk}'
            query[:endkey] = '#{ek}'
        # TODO: Handle the case when the key is a Hash
        end

        vs = variables.to_a.map do |k, v|
            if v =~ /\s/
                "-v:#{k} '#{v}'"
            else
                "-v:#{k} #{v}"
            end
        end.join(' ')
        qs = query.to_a.map { |k, v| "#{k}=#{v}" }.join('&')

        # Generate blitz query URL's with all sorts of randomization
        @urls << {
            :reduce => reduce ? true : false,
            :design => design,
            :view => view,
            :url => "#{vs} #{db.to_s}/_design/#{design}/_view/#{view}?#{qs}"
        }
    end

    def output_urls db
        puts
        msg "Here are full parameterized blitz URL's for each view. Simply copy "
        msg "paste these into the blitz bar @ http://blitz.io to generate load "
        msg "on your couch."
        puts
        puts urls.map { |u| u[:url] }.join("\n\n")
        puts
        puts
    end
end
end # Command
end # Blitz