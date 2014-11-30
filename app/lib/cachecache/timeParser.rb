module CacheCache
    class TimeParser
        REGEX = /^\/Date\((\d+)-(\d{2})(\d{2})\)\/$/

        def parse(date)
            match = REGEX.match(date)
            return nil unless match
            seconds_epoch = match[1].to_i / 1000
            timezone_hours = match[2].to_i * 60 * 60
            timezone_minutes = match[3].to_i * 60
            return Time.at(seconds_epoch - timezone_hours - timezone_minutes).utc
        end

        def iso8601(date)
            parsed = parse(date)
            return nil unless parsed
            parsed.iso8601
        end
    end
end
