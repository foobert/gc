require 'date'
require 'net/http'
require 'json'
require 'rest_client'

module CacheCache
    class Geocaching
        MAX_PER_PAGE = 30
        DISTANCE = 50000

        attr_reader :liteLeft, :fullLeft

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

        def livePost(path, data)
            uri = URI("https://api.groundspeak.com#{path}?format=json")
            Net::HTTP.start(uri.host, uri.port, :use_ssl => true) do |http|
                request = Net::HTTP::Post.new(uri.request_uri)
                if data.respond_to? :to_json
                    request.body = data.to_json
                else
                    request.body = data.to_s
                end
                request["Content-Type"] = "application/json"
                request["Accept-Language"] = "en-us"
                request["Accept"] = "*/*"
                request["Accept-Encoding"] = "gzip, deflate"
                request["User-Agent"] = "Geocaching/6.1 CFNetwork/672.0.8 Darwin/14.0.0"
                request["Connection"] = "keep-alive"

                response = http.request(request)
                #p response
                return nil if response.code != "200"

                data = JSON.parse(response.body)
                return data
            end
        end

        def search(accessToken, lat, lon)
            req = {
                "AccessToken" => accessToken,
                "IsLite" => true,
                "MaxPerPage" => MAX_PER_PAGE,
                "GeocachingLogCount" => 5,
                "TrackableLogCount" => 0,
                "PointRadius" => {"DistanceInMeters" => "#{DISTANCE}.000000", "Point" => {"Latitude" => lat, "Longitude" => lon }},
                "GeocacheExclusions" => {"Archived" => false, "Available" => false, "Premium" => false }
            }
            data = livePost('/LiveV6IAP/Geocaching.svc/SearchForGeocaches', req)

            status = data["Status"]
            return nil if status.nil? or status["StatusCode"] != 0

            @liteLeft = data["CacheLimits"]["CachesLeft"]

            return data["Geocaches"]
        end

        def getMore(accessToken, startIndex)
            req = {
                "AccessToken" => accessToken,
                "IsLite" => true,
                "StartIndex" => startIndex,
                "MaxPerPage" => MAX_PER_PAGE,
                "GeocacheLogCount" => 5,
                "TrackableLogCount" => 0,
            }
            data = livePost('/LiveV6/Geocaching.svc/GetMoreGeocaches', req)
            status = data["Status"]
            if status.nil? or status["StatusCode"] != 0
                p status
                return nil
            end

            @liteLeft = data["CacheLimits"]["CachesLeft"]

            return data["Geocaches"]
        end

        def searchMany(accessToken, lat, lon, count)
            if block_given?
                found = 0
                tmp = search(accessToken, lat, lon)
                found += tmp.size
                yield tmp
                while found < count
                    sleep 10
                    tmp = getMore(accessToken, found)
                    break if tmp.size == 0
                    found += tmp.size
                    yield tmp
                end
            else
                result = search(accessToken, lat, lon)
                while result.size < count
                    sleep 10
                    tmp = getMore(accessToken, result.size)
                    break if tmp.size == 0
                    result |= tmp
                end
                return result
            end
        end

        def details(accessToken, codes)
            req = {
                "AccessToken" => accessToken,
                "IsLite" => false,
                "MaxPerPage" => codes.size,
                "GeocachingLogCount" => 5,
                "TrackableLogCount" => 0,
                "CacheCode" => { "CacheCodes" => codes }
            }
            data = livePost('/LiveV6IAP/Geocaching.svc/SearchForGeocaches', req)
            status = data["Status"]
            return nil if status.nil? or status["StatusCode"] != 0
            @fullLeft = data["CacheLimits"]["CachesLeft"]
            return data["Geocaches"]
        end

        def userLogs(accessToken, username, lastlog)
            logs  = []
            max = 200
            loop do
                req = {
                    "AccessToken" => accessToken,
                    "Username" => username,
                    "MaxPerPage" => max,
                    "LogTypes" => [2],
                    "StartIndex" => logs.size,
                }
                data = livePost('/LiveV6IAP/geocaching.svc/GetUsersGeocacheLogs', req)
                status = data["Status"]
                return nil if status.nil? or status["StatusCode"] != 0

                data["Logs"].each do |log|
                    return logs if log["Code"] == lastlog
                    logs << log
                end

                break if data["Logs"].size < max
                sleep 10
            end
            return logs.reverse
        end

        def self.parse_date(strangeDate)
            Date.strptime(strangeDate[6..-3], "%Q")
        end
    end
end
