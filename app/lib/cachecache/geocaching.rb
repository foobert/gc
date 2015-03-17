require 'logging'
require 'net/http'
require 'json'
require 'enumerator'

module CacheCache
    class Geocaching
        MAX_PER_PAGE = 50
        MAX_LOGS = 30
        SEARCH_DISTANCE = 50000

        def initialize
            @logger = Logging.logger[self]
        end

        def login(username, password, consumerKey)
            uri = URI('https://api.groundspeak.com/AccountV4/AccountServicePublic.svc/Login?format=json')

            Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
                request = Net::HTTP::Post.new(uri.request_uri)
                request.body = "{\"Password\":\"#{password}\",\"UserName\":\"#{username}\",\"ConsumerKey\":\"#{consumerKey}\"}"
                request["Content-Type"] = "application/json"
                request["Accept-Language"] = "en-us"
                request["Accept"] = "*/*"
                request["Accept-Encoding"] = "gzip, deflate"
                request["User-Agent"] = "Geocaching/6.1 CFNetwork/672.0.8 Darwin/14.0.0"
                request["Connection"] = "keep-alive"

                response = http.request(request)
                #p response.code
                return nil if response.code != "200"

                data = JSON.parse(response.body)
                #p data

                status = data["Status"]
                return nil if status.nil? or status["StatusCode"] != 0

                accessToken = data["GroundspeakAccessToken"]
                return accessToken
            end
        end

        # Searches for geocaches near the given coordinates.
        #
        # The returned geocache objects will only have basic data fields
        # populated, e.g. no hints or description.
        #
        # @param accessToken [String] The access token for the Geocaching.com API
        # @param lat [float] The latitude of the center of the search in decimal degrees
        # @param lon [float] The longitude of the center of the search in decimal degrees
        # @param count [int] The maximum number of geocaches to return.
        # @param block The block to execute for the current (partial) search result
        def search_geocaches(accessToken, lat, lon, count)
            # TODO return an enumerator instead
            raise ArgumentError, "search_geocaches must be called with a block" if not block_given?

            found = 0
            tmp = _search_first(accessToken, lat, lon)
            found += tmp.size
            yield tmp
            while found < count
                tmp = _search_more(accessToken, found)
                break if tmp.size == 0
                found += tmp.size
                yield tmp
            end
        end

        # Does an initial search for geocaches near the given coordinates.
        #
        # The returned geocache objects will only have basic data fields
        # populated, e.g. no hints or description.
        #
        # @param accessToken [String] The access token for the Geocaching.com API
        # @param lat [float] The latitude of the center of the search in decimal degrees
        # @param lon [float] The longitude of the center of the search in decimal degrees
        # @returns A list of geocache objects as returned by the Geocaching.com API
        def _search_first(accessToken, lat, lon)
            req = {
                'AccessToken' => accessToken,
                'IsLite' => true,
                'MaxPerPage' => MAX_PER_PAGE,
                'GeocachingLogCount' => 5,
                'TrackableLogCount' => 0,
                'PointRadius' => {
                    'DistanceInMeters' => "#{SEARCH_DISTANCE}.000000",
                    'Point' => {
                        'Latitude' => lat,
                        'Longitude' => lon
                    }
                }
            }

            data = _post('/LiveV6IAP/Geocaching.svc/SearchForGeocaches', req)

            _check_result(data)
            _log_limit('lite', data)

            return data['Geocaches']
        end

        # Searches for more geocaches based on the last invocation of
        # _search_init.
        #
        # @param accessToken [String] The access token for the Geocaching.com API
        # @param startIndex [int] The offset for the search.
        def _search_more(accessToken, startIndex)
            req = {
                'AccessToken' => accessToken,
                'IsLite' => true,
                'StartIndex' => startIndex,
                'MaxPerPage' => MAX_PER_PAGE,
                'GeocacheLogCount' => 5,
                'TrackableLogCount' => 0,
            }

            data = _post('/LiveV6IAP/Geocaching.svc/GetMoreGeocaches', req)

            _check_result(data)
            _log_limit('lite', data)

            return data['Geocaches']
        end

        # Gets detailed information for a list of GC codes.
        #
        # @param accessToken [String] The access token for the Geocaching.com API
        # @param codes [Array[String]] The list of GC codes
        # @returns a list of geocache objects
        def get_geocaches(accessToken, codes)
            # the geocaching.com API does not allow request larger than
            # MAX_PER_PAGE
            # TODO do we need rate limiting here?
            result = []
            codes.each_slice(MAX_PER_PAGE) do |slice|
                req = {
                    'AccessToken' => accessToken,
                    'IsLite' => false,
                    'MaxPerPage' => slice.size,
                    'GeocachingLogCount' => 5,
                    'TrackableLogCount' => 0,
                    'CacheCode' => { 'CacheCodes' => slice }
                }
                data = _post('/LiveV6IAP/Geocaching.svc/SearchForGeocaches', req)
                _check_result(data)
                _log_limit('full', data)
                result += data['Geocaches']
            end
            result
        end

        # Gets found logs for a given user.
        #
        # @param username The username of the user.
        def get_user_logs(accessToken, username)
            found = 0
            loop do
                req = {
                    'AccessToken' => accessToken,
                    'Username' => username,
                    'MaxPerPage' => MAX_LOGS,
                    'LogTypes' => [2],
                    'StartIndex' => found,
                }
                data = _post('/LiveV6IAP/Geocaching.svc/GetUsersGeocacheLogs', req)

                _check_result(data)

                logs = data['Logs']
                yield logs
                found += logs.size
                break if logs.size < MAX_LOGS
            end
        end

        private
        def _post(path, data)
            uri = URI("https://api.groundspeak.com#{path}?format=json")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
                request = Net::HTTP::Post.new(uri.request_uri)
                if data.respond_to? :to_json
                    request.body = data.to_json
                else
                    request.body = data.to_s
                end
                request['Content-Type'] = 'application/json'
                request['Accept-Language'] = 'en-us'
                request['Accept'] = '*/*'
                request['Accept-Encoding'] = 'gzip, deflate'
                request['User-Agent'] = 'Geocaching/6.1 CFNetwork/672.0.8 Darwin/14.0.0'
                request['Connection'] = 'keep-alive'

                response = http.request(request)
                if response.code != '200'
                    raise GeocachingError, "Received non 200-OK response: #{response.code} #{response.message}"
                end

                data = JSON.parse(response.body)
                return data
            end
        end

        def _check_result(data)
            status = data['Status']
            raise GeocachingError, 'Result contained no status information' if status.nil?
            raise GeocachingError, "Request failed: #{status['StatusCode']} #{status['StatusMessage']}" if status['StatusCode'] != 0
        end

        def _log_limit(type, data)
            liteLeft = data['CacheLimits']['CachesLeft']
            @logger.debug "API Limit (#{type}): #{liteLeft}"
        end
    end

    class GeocachingError < StandardError
    end
end

