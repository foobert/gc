require 'logging'
require 'sinatra/base'
require 'sinatra/json'

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

        before do
            headers 'Access-Control-Allow-Origin' => '*', 'Access-Control-Allow-Methods' => ['OPTIONS', 'GET']
        end

        get '/' do
            json({'info' => 'cachecache'})
        end

        get '/geocaches' do
            json @db.get_geocaches.map {|g| g['Code'] }
        end

        get %r{/geocaches/(GC.+)} do |id|
            geocache =  @db.get_geocache(id)
            return 404 if geocache.nil?
            json geocache['data']
        end

        get '/poi.csv' do
            geocaches = @db.get_geocaches exclude_finds_by: params[:exclude], near: params[:near]
            pois = @poi.csv(geocaches, type: (params[:type] || "").to_sym)
            [200, {'Content-Type' => 'text/csv;charset=utf-8;'}, pois]
        end

        get '/poi.gpx' do
            geocaches = @db.get_geocaches exclude_finds_by: params[:exclude], near: params[:near]
            gpx = @poi.gpx(geocaches, type: (params[:type] || "").to_sym)
            [200, {'Content-Type' => 'application/xml'}, gpx]
        end

        get '/geofence' do
            geocaches = @db.geofence(params[:lat0].to_f, params[:lng0].to_f, params[:lat1].to_f, params[:lng1].to_f)
            json geocaches
        end
    end
end
