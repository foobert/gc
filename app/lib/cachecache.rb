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

        logs = _get_logs(username, lastlog)
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

    def _get_logs(username, lastlog)
        logs = []
        @geo.get_user_logs(@config.accessToken, username) do |chunk|
            chunk.each do |log|
                return logs.reverse if log['Code'] == lastlog
                logs << log
            end
            @logger.debug "Found #{logs.size} logs so far"
        end
        return logs.reverse
    end


    def search_caches(lat, lon)
        count_total = 0
        count_updated = 0
        @logger.debug "Searching near #{lat} #{lon}"
        @geo.search_geocaches(@config.accessToken, lat, lon, 2000) do |caches|
            @logger.debug "Found #{caches.size} caches"
            count_total += caches.size

            caches.group_by {|gc| @db.need_update?(gc) }.each do |update, gcs|
                codes = gcs.map {|gc| gc["Code"] }
                if update
                    @logger.debug "Updating #{codes.size} caches"
                    count_updated += codes.size
                    full = @geo.get_geocaches(@config.accessToken, codes)
                    @db.save_geocaches full
                else
                    @logger.debug "Touching #{codes.size} caches"
                    @db.touch_geocaches codes
                end
            end
        end
        puts "Found #{count_total} and updated #{count_updated} (#{(count_updated.to_f / count_total * 100).to_i}%) geocaches."
    end

    def get(ids)
        @logger.debug "Updating #{ids.size} caches"
        full = @geo.get_geocaches(@config.accessToken, ids)
        @db.save_geocaches full
    end
end
