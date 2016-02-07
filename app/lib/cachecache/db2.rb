require 'logging'
require 'time'
require 'set'
require 'uri'
require 'rest-client'
require 'open-uri'

module CacheCache
    class DB
        def initialize(uri, token)
            @logger = Logging.logger[self]

            @db_uri = uri
            @token = token
            @logger.debug "Using db #{@db_uri} with token #{@token}"
        end

        def need_update?(gc)
            stored = _get_gc(gc['Code'])
            return true if not stored
            @logger.debug "got stored cache: #{stored['DateLastUpdate']} vs #{gc['DateLastUpdate']}"
            return stored['DateLastUpdate'] != gc['DateLastUpdate']
        end

        def save_geocaches(data_array)
            @logger.debug "Updating #{data_array.size} Geocaches"
            data_array.each do |data|
                @logger.debug "POST #{data['Code']}"
                RestClient.post _url('/geocache'), data.to_json, 'X-Token' => @token, :accept => :json, :content_type => :json
            end
        end

        def touch_geocaches(ids)
            ids.each do |id|
                @logger.debug "PUT #{id}"
                RestClient.put _url("/geocache/#{id}/seen"), '', 'X-Token' => @token
            end
        end

        def get_latest_log(username)
            begin
                res = RestClient.get _url("/logs/latest?username=#{username}"), 'X-Token' => @token
                res.body
            rescue => ex
                @logger.error ex
                return nil
            end
        end

        def save_logs(data_array)
            @logger.debug "Updating #{data_array.size} Logs"
            data_array.each do |data|
                @logger.debug "POST #{data['Code']}"
                RestClient.post _url('/log'), data.to_json, 'X-Token' => @token, :accept => :json, :content_type => :json
            end
        end

        def save_log(data)
            @logger.debug "POST #{data['Code']}"
            RestClient.post _url('/log'), data.to_json, 'X-Token' => @token, :accept => :json, :content_type => :json
        end

        def get_geocache_name(id)
            gc = _get_gc(id)
            if gc
                gc['Name']
            else
                nil
            end
        end

        def get_stale_geocaches(days)
            res = open _url("/geocaches?stale=> #{days} days")
            JSON.parse res.read
        end

        private
        def _url(path)
            @db_uri + path
        end

        def _get_gc(id)
            @logger.debug "GET #{id}"
            begin
                # RestClient has some strange problems detecting the proper
                # encoding
                res = open _url("/geocaches/#{id}")
                JSON.parse res.read
            rescue => ex
                @logger.error ex
                return nil
            end
        end
    end
end
