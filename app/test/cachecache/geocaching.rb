require 'cachecache/geocaching'

require 'minitest/autorun'
require 'webmock/minitest'
require 'json'


describe CacheCache::Geocaching do
    before do
        WebMock.reset!
        @geo = CacheCache::Geocaching.new
    end

    describe 'search for geocaches' do
        it 'must work on small result sets' do
            limit = CacheCache::Geocaching::MAX_PER_PAGE - 1

            stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(build_geocache_response(1, limit))
                .to_raise
            stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/GetMoreGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(build_geocache_response(0, -1))
                .to_raise

            expected = build_geocaches(1, limit)
            result = []
            @geo.search_geocaches('TOKEN', 20, -30, 1000) do |geocaches|
                result += geocaches
            end
            result.must_equal expected
        end

        it 'must return all geocaches' do
            stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(build_geocache_response(1, 50))
                .to_raise

            stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/GetMoreGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(build_geocache_response(51, 100))
                .to_return(build_geocache_response(101, 120))
                .to_return(build_geocache_response(0, -1))
                .to_raise

            expected = build_geocaches(1, 120)
            result = []
            @geo.search_geocaches('TOKEN', 20, -30, 1000) do |geocaches|
                result += geocaches
            end
            result.must_equal expected
        end

        it 'must send the access token' do
            a = stub_request(:post, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .with(:body => /"AccessToken":"FOOBAR_TOKEN"/)
                .to_return(build_geocache_response(1, 10))
            b = stub_request(:post, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/GetMoreGeocaches')
                .with(:query => {'format' => 'json'})
                .with(:body => /"AccessToken":"FOOBAR_TOKEN"/)
                .to_return(build_geocache_response(0, -1))
            @geo.search_geocaches('FOOBAR_TOKEN', 20, -30, 1000) {|geocaches| }

            assert_requested(a)
            assert_requested(b)
        end

        it 'must raise an error on non-200 responses' do
            stub_request(:post, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(:status => [500, 'awww snap'])

            error = lambda { @geo.search_geocaches('', 0, 0, 1000) {|geocaches| } }.must_raise GeocachingError
            error.message.must_match /awww snap/
            error.message.must_match /500/
        end

        it 'must raise an error when GetMoreCaches fails' do
            stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(build_geocache_response(1, 50))
                .to_raise

            stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/GetMoreGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(:status => [500, 'awww snap'])

            result = []
            error = lambda { @geo.search_geocaches('', 0, 0, 1000) {|geocaches| result += geocaches } }.must_raise GeocachingError
            error.message.must_match /awww snap/
            error.message.must_match /500/

            # the first result must still be there
            build_geocaches(1, 50).must_equal result
        end

        it 'must handle failed requests' do
            stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(:body => {'Status' => {'StatusCode' => 55, 'StatusMessage' => 'Search not found'}}.to_json)
                .to_raise
            lambda { @geo.search_geocaches('', 0, 0, 1000) {|geocaches| } }.must_raise GeocachingError
        end
    end

    describe 'getting geocache details' do
        it 'must return all geocaches' do
            expected = build_geocaches(1, CacheCache::Geocaching::MAX_PER_PAGE+1)
            codes = expected.map {|gc| gc['Code'] }
            stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(build_geocache_response(1, 50))
                .to_return(build_geocache_response(51, 51))
                .to_raise

            result = @geo.get_geocaches('TOKEN', codes)
            result.must_equal expected
        end

        it 'must honor max request size' do
            codes = build_geocaches(1, CacheCache::Geocaching::MAX_PER_PAGE+1).map {|gc| gc['Code'] }
            a = stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(build_geocache_response(1, 50))
                .to_return(build_geocache_response(51, 51))
                .to_raise

            @geo.get_geocaches('TOKEN', codes)
            assert_requested(a, :times => 2)
        end

        it 'must send the access token' do
            a = stub_request(:post, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .with(:body => /"AccessToken":"FOOBAR_TOKEN"/)
                .to_return(build_geocache_response(1, 10))
            @geo.get_geocaches('FOOBAR_TOKEN', ['GC001'])

            assert_requested(a)
        end

        it 'must raise an error on non-200 responses' do
            stub_request(:post, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/SearchForGeocaches')
                .with(:query => {'format' => 'json'})
                .to_return(:status => [500, 'awww snap'])

            error = lambda { @geo.get_geocaches('TOKEN', ['GC001']) }.must_raise GeocachingError
            error.message.must_match /awww snap/
            error.message.must_match /500/
        end
    end

    describe 'getting user logs' do
        it 'must get all logs' do
            stub_request(:any, 'https://api.groundspeak.com/LiveV6IAP/Geocaching.svc/GetUsersGeocacheLogs')
                .with(:query => {'format' => 'json'})
                .to_return(lambda do |request|
                    req = JSON.parse(request.body)
                    start = req['StartIndex']
                    max = req['MaxPerPage']
                    top = [1, 120 - start].max
                    bottom = [1, top - max].max
                    return build_logs_response(top, bottom)
                end)
            expected = build_logs(120, 1).reverse
            result = []
            @geo.get_user_logs('TOKEN', 'username') {|logs| result += logs }
            result.reverse.must_equal expected
        end
    end

    def build_geocaches(from, to)
        (from..to).map do |i|
            {'Code' => 'GC' + i.to_s.rjust(3, '0')}
        end
    end

    def build_geocache_response(from, to)
        geocaches = build_geocaches(from, to)
        return {
            :body => {
                'Status' => {'StatusCode' => 0, 'StatusMessage' => 'Okay'},
                'CacheLimits' => {'CachesLeft' => 1000},
                'Geocaches' => geocaches
            }.to_json
        }
    end

    def build_logs(from, to)
        (to..from).map do |i|
            {'Code' => 'GL' + i.to_s.rjust(3, '0')}
        end.reverse
    end

    def build_logs_response(from, to)
        logs = build_logs(from, to)
        return {
            :body => {
                'Status' => {'StatusCode' => 0, 'StatusMessage' => 'Okay'},
                'Logs' => logs
            }.to_json
        }
    end
end

