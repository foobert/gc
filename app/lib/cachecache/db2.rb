require 'rethinkdb'
require 'logging'
require 'time'
require 'set'
require 'uri'

module CacheCache
    class DB
        include RethinkDB::Shortcuts

        def initialize
            @logger = Logging.logger[self]

            tries = 0
            begin
                dbs = _run {|r| r.db_list() }
                _init_db() if not dbs.include? 'gc'
            rescue
                if (tries += 1) < 5
                    @logger.warn "DB connection failed. Retrying..."
                    sleep 1
                    retry
                else
                    raise
                end
            end
        end

        def get_geocache(id)
            _run {|r| r.table('geocaches').get(id.downcase) }
        end

        def get_geocaches(opts = {})
            opts[:near] = nil if opts[:near] == ""
            if opts[:near]
                center_lat, center_lng = *(opts[:near].split(',').map {|x| x.to_f })
                lat0 = center_lat - 0.5
                lat1 = center_lat + 0.5
                lng0 = center_lng - 0.5
                lng1 = center_lng + 0.5
            end
            geocaches = _connect do |c|
                q = r.table('geocaches')
                if opts[:near]
                    q = q.between(lat0, lat1, {:index => 'lat'})
                end
                q = q['data']
                q = q.pluck(
                    'Code', 'Name',
                    {'CacheType' => 'GeocacheTypeId'},
                    {'ContainerType' => 'ContainerTypeName'},
                    'Available', 'Archived',
                    'Difficulty', 'Terrain',
                    'EncodedHints',
                    'Latitude', 'Longitude')
                q.run(c).to_a
            end
            if opts[:exclude_finds_by]
                username = opts[:exclude_finds_by]
                logs = Set.new(get_logs(username: username).map {|l| l['CacheCode']})
                geocaches.reject! {|g| logs.include? g['Code'] }
            end

            if opts[:near]
                geocaches.reject! {|g| g['Longitude'] < lng0 || g['Longitude'] > lng1 }
            end

            geocaches
        end

        def get_geocache_name(gc)
            _run {|r| r.table('geocaches').get(gc.downcase).default({"data" => {"Name" => nil }})["data"]["Name"] }
        end

        def geofence(lat0, lng0, lat1, lng1)
            lat_matches = _connect do |c|
                q = r.table('geocaches').between(lat0, lat1, {:index => 'lat'})['data'].pluck('Code', 'Name', 'Latitude', 'Longitude', 'ContainerType', 'CacheType')
                q.run(c).to_a
            end

            lng_matches = _connect do |c|
                q = r.table('geocaches').between(lng0, lng1, {:index => 'lng'})['data']['Code']
                Set.new q.run(c).to_a
            end

            geocaches = lat_matches.select {|g| lng_matches.include? g['Code'] }
            #geocaches.reject! {|g| g['CacheType']['GeocacheTypeId'] != 137 }

=begin
            _connect do |c|
                q = r.table('geocaches').filter do |g|
                    g['data']['Latitude'].gt(lat0).and(
                    g['data']['Latitude'].lt(lat1)).and(
                    g['data']['Longitude'].gt(lng0)).and(
                    g['data']['Longitude'].lt(lng1))
                end
                q = q['data'].pluck('Code', 'Name', 'Latitude', 'Longitude')
                q.run(c).to_a
            end
=end
            geocaches
        end

        def need_update?(gc)
            id = gc["Code"].downcase
            result = _run {|r| r.table('geocaches').get(id).default({'data' => {'DateLastUpdate' => nil}})['data']['DateLastUpdate'] }
            #@logger.debug "needUpdate of #{id}: #{result}"
            return result.nil? || gc['DateLastUpdate'] != result
        end

        def save_geocache(data)
            @logger.debug "Updating Geocache #{id}"
            saveGeocaches([data])
        end

        def save_geocaches(data_array)
            @logger.debug "Updating #{data_array.size} Geocaches"
            now = DateTime.now.to_s
            docs = data_array.map do |data|
                id = data["Code"].downcase
                {id: id, updated: now, data: data}
            end
            _run {|r| r.table('geocaches').insert(docs, upsert: true) }
        end

        def touch_geocache(id)
            _run {|r| r.table('geocaches').get(id.downcase).update({updated: DateTime.now.to_s}) }
        end

        def touch_geocaches(ids)
            now = DateTime.now.to_s
            _run {|r| r.table('geocaches').get_all(*ids.map(&:downcase)).update({updated: now}) }
        end

        def get_log(id)
            _run {|r| r.table('logs').get(id.downcase) }
        end

        def get_logs(opts = {})
            _connect do |c|
                q = r.table('logs')["data"]
                if opts[:username]
                    q = q.filter({"Finder" => {"UserName" => opts[:username]}})
                end
                q = q.pluck("CacheCode", {"LogType" => "WptLogTypeId"}, "UTCCreateDate", "VisitDate")
                q.run(c).to_a
            end
        end

        def get_latest_log(username)
            _run {|r| r.table('logs')['data'].filter({"Finder" => {"UserName" => username}}).order_by(r.desc("VisitDate")).limit(1)["Code"] }.first
        end

        def save_log(log)
            save_logs([log])
        end

        def save_logs(data_array)
            @logger.debug "Updating #{data_array.size} Logs"
            now = DateTime.now.to_s
            docs = data_array.map do |data|
                id = data["Code"].downcase
                {id: id, updated: now, data: data}
            end
            _run {|r| r.table('logs').insert(docs, upsert: true) }
        end

        private
        def _run
            _connect do |conn|
                query = yield r
                query.run(conn)
            end
        end

        def _connect
            db = ENV['GC_DB_1_PORT_28015_TCP'] || ENV['DB']
            @logger.debug "Using db #{db}"
            db_uri = URI(db)
            conn = r.connect(:host => db_uri.host, :port => db_uri.port, :db => 'gc')
            result = yield conn
            conn.close
            result
        end

        def _init_db
            _connect do |conn|
                r.db_create('gc').run(conn)
                r.db('gc').table_create('geocaches').run(conn)
                r.db('gc').table_create('logs').run(conn)
            end
            @logger.info 'Database initialized'
        end
    end
end
