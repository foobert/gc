module CacheCache
    class TimeParser
        REGEX = /^\/Date\((\d+)(([+-])(\d{2})(\d{2}))?\)\/$/

        def parse(date)
            match = REGEX.match(date)
            return nil unless match

            seconds_epoch = match[1].to_i / 1000
            timezone_factor = match[3] == '-' ? 1 : -1
            timezone_hours = match[4].to_i * 60 * 60
            timezone_minutes = match[5].to_i * 60

            return Time.at(seconds_epoch + timezone_factor * (timezone_hours + timezone_minutes)).utc
        end
    end
end
