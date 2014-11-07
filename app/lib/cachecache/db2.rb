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

            _check_db()
            _init_inidices()
        end

        def get_geocache(id)
            _run {|r| r.table('geocaches').get(id.downcase) }
        end

        def get_geocaches(opts = {})
            @logger.debug "get_geocaches, opts: #{opts.inspect}"
            geocaches = _connect do |c|
                q = r.table('geocaches')
                if opts[:bounds]
                    @logger.debug "filtering by geofence"
                    lat0, lng0, lat1, lng1 = *opts[:bounds]
                    bounds = r.polygon(
                        r.point(lng0, lat0),
                        r.point(lng0, lat1),
                        r.point(lng1, lat1),
                        r.point(lng1, lat0))
                    q = q.get_intersecting(bounds, {:index => 'coords'})
                end
                if opts[:typeIds]
                    @logger.debug "filtering by typeIds"
                    q = q.filter {|doc| opts[:typeIds][1..-1].inject(doc['data']['CacheType']['GeocacheTypeId'].eq(opts[:typeIds].first)) {|s, x| s | doc['data']['CacheType']['GeocacheTypeId'].eq(x) }}
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
                @logger.debug q.inspect
                q.run(c).to_a
            end

            geocaches = _filterLogs(geocaches, opts[:excludeFinds])

            @logger.debug "found #{geocaches.size} geocaches"

            geocaches
        end

        def get_geocache_name(gc)
            return nil if gc.nil?
            _run {|r| r.table('geocaches').get(gc.downcase).default({"data" => {"Name" => nil }})["data"]["Name"] }
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

        def _check_db
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

        def _init_db
            _connect do |conn|
                r.db_create('gc').run(conn)
                r.db('gc').table_create('geocaches').run(conn)
                r.db('gc').table_create('logs').run(conn)
            end
            @logger.info 'Database initialized'
        end

        def _init_inidices
            _connect do |c|
                _create_index(c, 'coords', :geo => true) do |doc|
                        {"$reql_type$" => "GEOMETRY", "coordinates" => [doc['data']['Longitude'], doc['data']['Latitude']], "type" => "Point"}
                end

                _create_index(c, 'GeocacheTypeId') do |doc|
                    doc['data']['CacheType']['GeocacheTypeId']
                end
            end
        end

        def _create_index(connection, name, opts = {}, &idx)
            begin
                r.table('geocaches').index_status(name).run(connection)
            rescue
                @logger.info "creating index #{name}"
                r.table('geocaches').index_create(name, opts, idx).run(connection)
            end
        end

        def _filterLogs(geocaches, users)
            return geocaches unless users
            @logger.debug "Filtering #{geocaches.size} geocaches against #{users.inspect}"
            users = [users] unless users.is_a? Array
            return geocaches if users.empty?
            logs = Set.new
            users.each {|username| logs += get_logs(username: username).map {|l| l['CacheCode'] } }
            @logger.debug "Found #{logs.size} caches to filter"
            return geocaches.reject {|g| logs.include? g['Code'] }
        end
    end
end
