require 'cachecache/timeParser'
require 'minitest/autorun'

describe CacheCache::TimeParser do
    before do
        @tp = CacheCache::TimeParser.new
    end

    describe 'parse' do
        it 'should parse dates' do
            parsed = @tp.parse('/Date(1413576001823-0700)/')
            parsed.must_equal Time.new(2014, 10, 17, 13, 00, 01, "+00:00").utc
        end

        it 'should parse publish dates' do
            parsed = @tp.parse('/Date(1180940400000-0700)/')
            parsed.must_equal Time.new(2007, 06, 04, 0, 0, 0, "+00:00").utc
        end

        it 'should return nil for invalid dates' do
            @tp.parse('').must_equal nil
            @tp.parse(nil).must_equal nil
            @tp.parse('foo').must_equal nil
        end
    end

    describe 'iso8601' do
        it 'should return iso8601 format' do
            iso = @tp.iso8601('/Date(1413576001823-0700)/')
            iso.must_equal '2014-10-17T13:00:01Z'
        end

        it 'should return nil for invalid dates' do
            @tp.iso8601('').must_equal nil
            @tp.iso8601(nil).must_equal nil
            @tp.iso8601('foo').must_equal nil
        end
    end
end
