require 'date'
require 'time'
require 'logging'

require 'cachecache/geocaching'
require 'cachecache/db2'
require 'cachecache/poi'

class CacheCache2
    def initialize(config)
        Logging.logger.root.appenders = Logging.appenders.stdout
        Logging.logger.root.level = config.log || :info

        @logger = Logging.logger[self]
        @config = config
        @db = CacheCache::DB.new
        @geo = CacheCache::Geocaching.new
    end

    def login(password)
        accessToken = @geo.login(@config.user, password, @config.consumerKey)
        puts accessToken
    end

    def update_logs(username)
        lastlog = @db.get_latest_log(username)
        @logger.debug "LastLog: #{lastlog}"

        logs = @geo.userLogs(@config.accessToken, username, lastlog)
        @logger.debug "Retrieved #{logs.size} logs since #{lastlog}"

        if logs.empty?
            @logger.debug "No new logs for #{username}."
            return
        end

        @db.save_logs(logs)

        puts "Latest logs for #{username}:"
        logs.each do |log|
            name = @db.get_geocache_name(log["CacheCode"])
            puts " - #{log["CacheCode"]} #{name}"
        end
    end

    def search_caches(lat, lon)
        count_total = 0
        count_updated = 0
        @logger.debug "Searching near #{lat} #{lon}"
        @geo.searchMany(@config.accessToken, lat, lon, 1000) do |caches|
            @logger.debug "Found #{caches.size} caches"
            count_total += caches.size

            caches.group_by {|gc| @db.need_update?(gc) }.each do |update, gcs|
                codes = gcs.map {|gc| gc["Code"] }
                if update
                    @logger.debug "Updating #{codes.size} caches"
                    count_updated += codes.size
                    full = @geo.details(@config.accessToken, codes)
                    @db.save_geocaches full
                    @logger.debug "Limits: Lite #{@geo.liteLeft}, Full #{@geo.fullLeft}"
                else
                    @logger.debug "Touching #{codes.size} caches"
                    @db.touch_geocaches codes
                end
            end
        end
        puts "Found #{count_total} and updated #{count_updated} (#{(count_updated.to_f / count_total * 100).to_i}%) geocaches."
    end

    def csv(username)
        geocaches = @db.get_geocaches exclude_finds_by: username
        poi = CacheCache::POI.new
        print poi.csv(geocaches).join
    end

    def get(ids)
        @logger.debug "Updating #{ids.size} caches"
        full = @geo.details(@config.accessToken, ids)
        @db.save_geocaches full
        @logger.debug "Limits: Lite #{@geo.liteLeft}, Full #{@geo.fullLeft}"
    end

    def clean
        old = @couch.byAge(5)
        if old.empty?
            puts "No old geocaches found."
        else
            puts "Found #{old.size} old geocaches. Deleting.."
            @couch.delete_bulk old.map {|o| {"_id" => o["id"], "_rev" => o["value"]["rev"]} }
        end
    end
end
