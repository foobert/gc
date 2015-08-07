require 'cachecache/timeParser'
require 'minitest/autorun'

describe CacheCache::TimeParser do
    before do
        @tp = CacheCache::TimeParser.new
    end

    describe 'parse' do
        it 'should parse dates without timezone information' do
            parsed = @tp.parse('/Date(1198908717056)/')
            parsed.must_equal Time.new(2007, 12, 29, 06, 11, 57, "+00:00").utc
        end

        it 'should parse dates with negative timezone information' do
            parsed = @tp.parse('/Date(1198908717056-0100)/')
            parsed.must_equal Time.new(2007, 12, 29, 06, 11, 57, "-01:00").utc
        end

        it 'should parse dates with positive timezone information' do
            parsed = @tp.parse('/Date(1198908717056+0100)/')
            parsed.must_equal Time.new(2007, 12, 29, 06, 11, 57, "+01:00").utc
        end

        it 'should return nil for invalid dates' do
            @tp.parse('').must_equal nil
            @tp.parse(nil).must_equal nil
            @tp.parse('foo').must_equal nil
        end
    end
end
