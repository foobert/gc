require 'logging'

require 'cachecache/geocaching'
require 'cachecache/db2'

class CacheCache2
    def initialize(accessToken: nil, db: nil, token: nil)
        @accessToken = accessToken

        @logger = Logging.logger[self]
        @db = CacheCache::DB.new(db, token)
        @geo = CacheCache::Geocaching.new
    end

    def login(user, password, consumerKey)
        p @geo.login(user, password, consumerKey)
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

        #@db.save_logs(logs)

        puts "Latest logs for #{username}:"
        logs.each do |log|
            #name = @db.get_geocache_name(log["CacheCode"])
            puts " - #{log["CacheCode"]}"# #{name}"
        end
    end

    def search_caches(lat, lon, count = 2000)
        count_total = 0
        count_updated = 0
        @logger.debug "Searching near #{lat} #{lon}, limit #{count}"
        @geo.search_geocaches(@accessToken, lat, lon, count) do |caches|
            @logger.debug "Found #{caches.size} caches"
            count_total += caches.size

            caches.group_by {|gc| @db.need_update?(gc) }.each do |update, gcs|
                codes = gcs.map {|gc| gc["Code"] }
                if update
                    @logger.debug "Updating #{codes.size} caches"
                    count_updated += codes.size
                    full = @geo.get_geocaches(@accessToken, codes)
                    @db.save_geocaches(full)
                else
                    @logger.debug "Touching #{codes.size} caches"
                    @db.touch_geocaches(codes)
                end
            end
        end
        puts "Found #{count_total} and updated #{count_updated} (#{(count_updated.to_f / count_total * 100).to_i}%) geocaches."
    end

    def get(ids)
        @logger.debug "Updating #{ids.size} caches"
        ids.each_slice(50) do |slice|
            slice.group_by {|gc| @db.get_geocache_name(gc).nil? }.each do |update, codes|
                if update
                    full = @geo.get_geocaches(@accessToken, codes)
                    @db.save_geocaches(full)
                else
                end
            end
        end
    end

    def update_stale
        @logger.debug "Getting geocaches older than 7 days"
        jobs = @db.get_stale_geocaches 7
        jobs.sort_by! {|job| job['meta']['updated'] }
        @logger.debug "Found #{jobs.size} stale geocaches"

        ids = jobs.map {|job| job["Code"] }
        ids.each_slice CacheCache::Geocaching::MAX_PER_PAGE do |slice|
            # no need to do a light search first, since they the geocaches are
            # stale we assume that we'll need a full get anyway
            get slice
        end
    end

    private
    def _get_logs(username, lastlog)
        logs = []
        @geo.get_user_logs(@accessToken, username) do |chunk|
            chunk.each do |log|
                return logs.reverse if log['Code'] == lastlog
                logs << log
                @db.save_log(log)
            end
            @logger.debug "Found #{logs.size} logs so far"
        end
        return logs.reverse
    end
end
