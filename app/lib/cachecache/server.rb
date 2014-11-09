require 'logging'
require 'sinatra/base'
require 'sinatra/json'
require 'sinatra/reloader'

require 'cachecache/db2'
require 'cachecache/poi'

module CacheCache
    class Server < Sinatra::Base
        def initialize(app = nil)
            super(app)

            Logging.logger.root.appenders = Logging.appenders.stdout
            Logging.logger.root.level = :debug

            @logger = Logging.logger[self]

            @db = CacheCache::DB.new
            @poi = CacheCache::POI.new
        end

        configure :development do
            register Sinatra::Reloader
        end

        before do
            headers 'Access-Control-Allow-Origin' => '*', 'Access-Control-Allow-Methods' => ['OPTIONS', 'GET']
        end

        get '/' do
            json({'info' => 'cachecache'})
        end

        get '/geocaches' do
            opts = _getOpts()
            json @db.get_geocaches(opts)
        end

        get %r{/geocaches/(GC.+)} do |id|
            geocache =  @db.get_geocache(id)
            return 404 if geocache.nil?
            json geocache['data']
        end

        get '/gcs' do
            opts = _getOpts()
            json @db.get_geocaches(opts).map {|g| g['Code'] }
        end

        get '/poi.csv' do
            opts = _getOpts()
            geocaches = @db.get_geocaches(opts)
            pois = @poi.csv(geocaches, type: (params[:type] || "").to_sym)
            [200, {'Content-Type' => 'text/csv;charset=utf-8;'}, pois]
        end

        get '/poi.gpx' do
            opts = _getOpts()
            geocaches = @db.get_geocaches(opts)
            gpx = @poi.gpx(geocaches, type: (params[:type] || "").to_sym)
            [200, {'Content-Type' => 'application/xml'}, gpx]
        end

        def _getOpts
            @logger.debug "Params: #{params.inspect}"
            opts = Hash.new

            unless params[:bounds].nil?
                halt 400, "Bounds must have four values" unless params[:bounds].is_a? Array and params[:bounds].size == 4
                opts[:bounds] = params[:bounds].map {|x| x.to_f }
            end

            unless params[:excludeFinds].nil?
                opts[:excludeFinds] = _opt_to_array(params[:excludeFinds])
            end

            unless params[:excludeDisabled].nil?
                opts[:excludeDisabled] = _opt_to_bool(params[:excludeDisabled])
            end

            unless params[:typeIds].nil?
                opts[:typeIds] = _opt_to_array(params[:typeIds].map {|x| x.to_i })
            end

            unless params[:full].nil?
                opts[:full] = _opt_to_bool(params[:full])
            end

            opts
        end

        def _opt_to_array(ary)
            return ary if ary.is_a? Array
            return [ary]
        end

        def _opt_to_bool(val)
            return val == "1"
        end
    end
end
