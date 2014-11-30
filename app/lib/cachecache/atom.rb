require 'builder'
require 'cachecache/timeParser'

module CacheCache
    class Atom
        def initialize
            @timeParser = TimeParser.new
        end

        def generate(geocaches)
            geocaches.sort_by! {|geocache| geocache['UTCPlaceDate'] }
            builder = Builder::XmlMarkup.new
            builder.instruct! :xml, :version=>"1.0", :encoding=>"UTF-8"
            builder.feed xmlns: 'http://www.w3.org/2005/Atom' do |feed|
                # TODO generate URL automatically
                feed.id 'http://gc.funkenburg.net/api/feed'
                feed.title 'Geocaches', type: 'text'
                feed.updated @timeParser.iso8601(geocaches.last['DateLastUpdate'])
                feed.link href: 'http://gc.funkenburg.net/api/feed', rel: 'self'
                geocaches.each do |geocache|
                    feed.entry do |entry|
                        # TODO generate URL prefix automatically
                        entry.id "http://gc.funkenburg.net/api/#{geocache['Code']}"

                        entry.author do |author|
                            author.name geocache['Owner']['UserName']
                        end
                        entry.title "#{geocache['Code']} - #{geocache['Name']}"
                        entry.link rel: 'alternate', type: 'text/html', href: geocache['Url']
                        if geocache['LongDescriptionIsHtml']
                            entry.content type: 'xhtml' do |content|
                                content.div xmlns: 'http://www.w3.org/1999/xhtml' do |div|
                                    geocache['LongDescription'].to_sym
                                end
                            end
                        else
                            entry.content geocache['LongDescription'], type: 'text'
                        end
                        placeDate = @timeParser.iso8601(geocache['UTCPlaceDate'])
                        entry.published placeDate
                        entry.updated placeDate
                        #entry.updated @timeParser.iso8601(geocache['DateLastUpdate'])
                    end
                end
            end
            builder.target!
        end
    end
end
