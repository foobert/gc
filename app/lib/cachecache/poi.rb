# encoding: utf-8
require 'logging'

module CacheCache
    class POI
        def initialize
            @logger = Logging.logger[self]
        end

        def csv(geocaches, opts = {})
            @logger.debug opts.inspect
            geocaches = _filter_geocaches(geocaches, opts)
            @logger.debug "generating csv of #{geocaches.size} geocaches"

            geocaches.map! do |geocache|
                name, desc = _get_name_and_desc(geocache, method(:_fix_csv_string))
                lat = geocache['Latitude']
                lon = geocache['Longitude']
                "#{lon},#{lat},\"#{name}\",\"#{desc}\"\n"
            end
        end

        def gpx(geocaches, opts = {})
            @logger.debug opts.inspect
            geocaches = _filter_geocaches(geocaches, opts)
            @logger.debug "generating gpx of #{geocaches.size} geocaches"

            output = <<EOS
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx
xmlns="http://www.topografix.com/GPX/1/1"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
version="1.1"
creator="cachecache">
EOS
            geocaches.each do |geocache|
                name, desc = _get_name_and_desc(geocache, method(:_fix_xml_string))
                lat = geocache['Latitude']
                lon = geocache['Longitude']
                output << "<wpt lat=\"#{lat}\" lon=\"#{lon}\">\n"
                output << "<name>#{name}</name>\n"
                output << "<cmt>#{desc}</cmt>\n"
                output << "<type>Geocache</type>\n"
                output << "</wpt>\n"
            end
            output << "</gpx>"
            output
        end

        private
        def _get_name_and_desc(geocache, string_fixer = nil)
            type = case geocache['CacheType']['GeocacheTypeId']
                   when 2
                       'T'
                   when 3
                       'M'
                   when 5
                       'L'
                   when 11
                       'W'
                   when 137
                       'E'
                   end
            code = geocache['Code'][2..-1]
            skill = geocache['Difficulty'].to_s + '/' + geocache['Terrain'].to_s
            size = geocache['ContainerType']['ContainerTypeName'][0..0]
            tmp_hint = geocache['EncodedHints'] || ''
            tmp_hint = string_fixer[tmp_hint] if string_fixer
            hint = tmp_hint[0, 4 * 48]
            name = geocache['Name']
            name = string_fixer[name] if string_fixer
            lat = geocache['Latitude']
            lon = geocache['Longitude']

            return [
                "#{code} #{size} #{type} #{skill}\n#{name}",
                hint
            ]
        end

        def _filter_geocaches(geocaches, opts)
            allowed_types = _get_allowed_types(opts[:type])
            @logger.debug "allowed types: #{allowed_types.inspect}"

            geocaches.reject do |g|
                next true if g["Archived"] or not g["Available"]
                next true unless allowed_types.include? g["CacheType"]["GeocacheTypeId"]

                next false
            end
        end

        def _get_allowed_types(allowed)
            @logger.debug "allowed: #{allowed}"
            case allowed
            when :traditional
                [2]
            when :multi
                [3]
            when :webcam
                [11]
            when :letterbox
                [5]
            when :earth
                [137]
            else
                [2,3,137,5,11]
            end
        end

        def _fix_xml_string(s)
            s.gsub! '&', '&amp;'
            s.gsub! '<', '&lt;'
            s.gsub! '>', '&gt;'
            s
        end

        def _fix_csv_string(s)
            s.gsub! 'ä', 'ae'
            s.gsub! 'ö', 'oe'
            s.gsub! 'ü', 'ue'
            s.gsub! 'Ä', 'AE'
            s.gsub! 'Ö', 'OE'
            s.gsub! 'Ü', 'UE'
            s.gsub! 'ß', 'ss'
            s.gsub! "\"", ''
            s.gsub! "\n", ' '
            s.gsub! "\r", ''
            s.gsub!(/ {2,}/, ' ')
            s
        end
    end
end
