ENV['RACK_ENV'] = 'test'

require 'rack/test'
require 'set'
require 'cachecache/server'

include Rack::Test::Methods

class MockDb
    GC001 = {
        'Code' => 'GC001',
        'CacheType' => { 'GeocacheTypeId' => 2 },
        'ContainerType' => { 'ContainerTypeName' => 'Regular' },
        'Difficulty' => 1,
        'Terrain' => 2,
        'Name' => 'Simple Tradi',
        'Latitude' => 10.1234,
        'Longitude' => -20.1234,
        'EncodedHints' => 'HintHint',
        'Available' => true,
        'Archived' => false,
        'Attributes' => [
            { 'AttributeTypeID' => 1, 'IsOn' => true },
            { 'AttributeTypeID' => 2, 'IsOn' => false },
        ],
    }
    GC002 = {
        'Code' => 'GC002',
        'CacheType' => { 'GeocacheTypeId' => 3 },
        'ContainerType' => { 'ContainerTypeName' => 'Small' },
        'Difficulty' => 1,
        'Terrain' => 2,
        'Name' => 'Simple Multi',
        'Latitude' => 10.1234,
        'Longitude' => -20.1234,
        'EncodedHints' => 'HintHint',
        'Available' => true,
        'Archived' => false,
        'Attributes' => [
            { 'AttributeTypeID' => 1, 'IsOn' => true },
        ],
    }
    GC003 = {
        'Code' => 'GC003',
        'CacheType' => { 'GeocacheTypeId' => 5 },
        'ContainerType' => { 'ContainerTypeName' => 'Small' },
        'Difficulty' => 1,
        'Terrain' => 2,
        'Name' => 'Simple Letterbox',
        'Latitude' => 10.1234,
        'Longitude' => -20.1234,
        'EncodedHints' => 'HintHint',
        'Available' => true,
        'Archived' => false,
        'Attributes' => [
            { 'AttributeTypeID' => 2, 'IsOn' => false },
        ],
    }

    def get_geocaches(opts = {})
        result = [GC001, GC002, GC003]
        if opts[:attributeIds]
            result.select! do |gc|
                exp = Set.new(opts[:attributeIds].map {|k,v| {'AttributeTypeID' => k, 'IsOn' => v} })
                tmp = (exp - Set.new(gc['Attributes']))
                tmp.size == 0
            end
        end
        result
    end

    def get_geocache(id)
        case id.downcase
        when 'gc001' then GC001
        when 'gc002' then GC002
        when 'gc003' then GC003
        else nil
        end
    end
end

def app
    CacheCache::Server.new(nil, :db => MockDb.new)
end

describe 'server' do
    before do
        Logging.logger.root.level = :warn
    end

    it 'should return basic info on root' do
        get '/api/'
        response = JSON.parse(last_response.body)
        response['info'].must_equal 'cachecache'
    end

    it 'should redirect /' do
        get '/'
        last_response.status.must_equal 302
        last_response.location.must_equal 'http://example.org/api/'
    end

    it 'should redirect /api' do
        get '/'
        last_response.status.must_equal 302
        last_response.location.must_equal 'http://example.org/api/'
    end

    describe '/api/gcs' do
        it 'should return geocache ids' do
            get '/api/gcs'
            JSON.parse(last_response.body).must_equal ['GC001', 'GC002', 'GC003']
        end
    end

    describe '/api/geocaches' do
        it 'should return a list of geocaches' do
            get '/api/geocaches'
            JSON.parse(last_response.body).must_equal [MockDb::GC001, MockDb::GC002, MockDb::GC003]
        end

        it 'should filter by positive attributes' do
            get '/api/geocaches?attributeIds[]=1'
            JSON.parse(last_response.body).must_equal [MockDb::GC001, MockDb::GC002]
        end

        it 'should filter by negative attributes' do
            get '/api/geocaches?attributeIds[]=!2'
            JSON.parse(last_response.body).must_equal [MockDb::GC001, MockDb::GC003]
        end

        it 'should filter by combined attributes' do
            get '/api/geocaches?attributeIds[]=1&attributeIds[]=!2'
            JSON.parse(last_response.body).must_equal [MockDb::GC001]
        end
    end

    describe '/api/geocaches/id' do
        it 'should return a single geocache' do
            get '/api/geocaches/GC002'
            JSON.parse(last_response.body).must_equal MockDb::GC002
        end

        it 'should return 404 for a non-existing id' do
            get '/api/geocaches/GC999'
            last_response.status.must_equal 404
        end
    end

    describe '/api/poi.csv' do
        it 'should return a CSV of all geocaches' do
            get '/api/poi.csv'
            # POI generation itself is tested seperately
            expected = CacheCache::POI.new.csv([MockDb::GC001, MockDb::GC002, MockDb::GC003]).join
            last_response.body.must_equal(expected)
        end

        it 'should filter types with :type param' do
            get '/api/poi.csv?type=traditional'
            expected = CacheCache::POI.new.csv([MockDb::GC001]).join
            last_response.body.must_equal(expected)
        end

    end
end
