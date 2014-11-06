require 'rethinkdb'
require 'logging'
require 'time'
require 'set'
require 'uri'
require 'connection_pool'

module CacheCache
    class DB
        include RethinkDB::Shortcuts

        def initialize
            @logger = Logging.logger[self]

            @db_uri = URI(ENV['GC_DB_1_PORT_28015_TCP'] || ENV['DB'])
            @logger.debug "Using db #{@db_uri}"
            @pool = ConnectionPool.new do
                r.connect(:host => @db_uri.host, :port => @db_uri.port, :db => 'gc')
            end

            tries = 0
            begin
                dbs = _run {|r| r.db_list() }
                _init_db() if not dbs.include? 'gc'
            rescue => ex
                @logger.error ex
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
            return nil if gc.nil?
            _run {|r| r.table('geocaches').get(gc.downcase).default({"data" => {"Name" => nil }})["data"]["Name"] }
        end

        def geofence(lat0, lng0, lat1, lng1)
            geocaches = []
            _connect do |c|
                begin
                    r.table('geocaches').index_status('coords').run(c)
                rescue
                    @logger.warn "creating coords index"
                    r.table('geocaches').index_create('coords', :geo => true) { |doc|
                        {"$reql_type$" => "GEOMETRY", "coordinates" => [doc['data']['Longitude'], doc['data']['Latitude']], "type" => "Point"}
                    }.run(c)
                end

                q = r.table('geocaches').get_intersecting(r.polygon(r.point(lng0, lat0), r.point(lng0, lat1), r.point(lng1, lat1), r.point(lng1, lat0)), {:index => 'coords'})
                q = q['data'].pluck('Code', 'Name', 'Latitude', 'Longitude', {'CacheType' => 'GeocacheTypeId'})
                geocaches = q.run(c).to_a
            end

            return geocaches
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
            _run {|r| r.table('geocaches').insert(docs, conflict: 'replace') }
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
            _run do |r|
                r.table('logs')['data']
                .filter({"Finder" => {"UserName" => username}})
                .order_by(r.desc("UTCCreateDate"))
                .limit(1)["Code"]
            end.first
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
            _run {|r| r.table('logs').insert(docs, conflict: 'replace') }
        end

        private
        def _run
            _connect do |conn|
                query = yield r
                query.run(conn)
            end
        end

        def _connect
            result = nil
            @pool.with do |conn|
                result = yield conn
            end
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
