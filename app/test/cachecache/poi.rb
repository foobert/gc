require 'cachecache/poi'

require 'minitest/autorun'

describe CacheCache::POI do
    before do
        @poi = CacheCache::POI.new
        @simple = [
            {
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
            },
            {
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
            },
            {
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
            },
            {
                'Code' => 'GC004',
                'CacheType' => { 'GeocacheTypeId' => 8 },
                'ContainerType' => { 'ContainerTypeName' => 'Small' },
                'Difficulty' => 1,
                'Terrain' => 2,
                'Name' => 'Simple Mystery',
                'Latitude' => 10.1234,
                'Longitude' => -20.1234,
                'EncodedHints' => 'HintHint',
                'Available' => true,
                'Archived' => false,
            },
            {
                'Code' => 'GC005',
                'CacheType' => { 'GeocacheTypeId' => 11 },
                'ContainerType' => { 'ContainerTypeName' => 'Small' },
                'Difficulty' => 1,
                'Terrain' => 2,
                'Name' => 'Simple Wherigo',
                'Latitude' => 10.1234,
                'Longitude' => -20.1234,
                'EncodedHints' => 'HintHint',
                'Available' => true,
                'Archived' => false,
            },
            {
                'Code' => 'GC006',
                'CacheType' => { 'GeocacheTypeId' => 137 },
                'ContainerType' => { 'ContainerTypeName' => 'Small' },
                'Difficulty' => 1,
                'Terrain' => 2,
                'Name' => 'Simple Earthcache',
                'Latitude' => 10.1234,
                'Longitude' => -20.1234,
                'EncodedHints' => 'HintHint',
                'Available' => true,
                'Archived' => false,
            },
        ]

        @mystery = {
            'Code' => 'GC007',
            'CacheType' => { 'GeocacheTypeId' => 8 },
            'ContainerType' => { 'ContainerTypeName' => 'Small' },
            'Difficulty' => 1,
            'Terrain' => 2,
            'Name' => 'Simple Mystery',
            'Latitude' => 10.1234,
            'Longitude' => -20.1234,
            'EncodedHints' => 'HintHint',
            'Available' => true,
            'Archived' => false,
        }
        @archived = {
            'Code' => 'GC008',
            'CacheType' => { 'GeocacheTypeId' => 3 },
            'ContainerType' => { 'ContainerTypeName' => 'Small' },
            'Difficulty' => 1,
            'Terrain' => 2,
            'Name' => 'Archived Multi',
            'Latitude' => 10.1234,
            'Longitude' => -20.1234,
            'EncodedHints' => 'HintHint',
            'Available' => true,
            'Archived' => true,
        }
        @inactive = {
            'Code' => 'GC009',
            'CacheType' => { 'GeocacheTypeId' => 3 },
            'ContainerType' => { 'ContainerTypeName' => 'Small' },
            'Difficulty' => 1,
            'Terrain' => 2,
            'Name' => 'Inactive Multi',
            'Latitude' => 10.1234,
            'Longitude' => -20.1234,
            'EncodedHints' => 'HintHint',
            'Available' => false,
            'Archived' => false,
        }
        @umlauts = {
            'Code' => 'GC010',
            'CacheType' => { 'GeocacheTypeId' => 2 },
            'ContainerType' => { 'ContainerTypeName' => 'Regular' },
            'Difficulty' => 1,
            'Terrain' => 2,
            'Name' => 'ä ö ü Ä Ö Ü ß',
            'Latitude' => 10.1234,
            'Longitude' => -20.1234,
            'EncodedHints' => 'ä ö ü Ä Ö Ü ß',
            'Available' => true,
            'Archived' => false,
        }
        @whitespace = {
            'Code' => 'GC011',
            'CacheType' => { 'GeocacheTypeId' => 2 },
            'ContainerType' => { 'ContainerTypeName' => 'Regular' },
            'Difficulty' => 1,
            'Terrain' => 2,
            'Name' => "foo\r\nbar\"    baz",
            'Latitude' => 10.1234,
            'Longitude' => -20.1234,
            'EncodedHints' => "foo\r\nbar\"    baz",
            'Available' => true,
            'Archived' => false,
        }
        @tags = {
            'Code' => 'GC012',
            'CacheType' => { 'GeocacheTypeId' => 2 },
            'ContainerType' => { 'ContainerTypeName' => 'Regular' },
            'Difficulty' => 1,
            'Terrain' => 2,
            'Name' => "<foo> & bar",
            'Latitude' => 10.1234,
            'Longitude' => -20.1234,
            'EncodedHints' => "<foo> & bar",
            'Available' => true,
            'Archived' => false,
        }
    end

    describe 'csv' do
        it 'generates a CSV of passed in geocaches' do
            csv = @poi.csv(@simple)
            expected = [
                "-20.1234,10.1234,\"001 R T 1/2\nSimple Tradi\",\"HintHint\"\n",
                "-20.1234,10.1234,\"002 S M 1/2\nSimple Multi\",\"HintHint\"\n",
                "-20.1234,10.1234,\"003 S L 1/2\nSimple Letterbox\",\"HintHint\"\n",
                "-20.1234,10.1234,\"005 S W 1/2\nSimple Wherigo\",\"HintHint\"\n",
                "-20.1234,10.1234,\"006 S E 1/2\nSimple Earthcache\",\"HintHint\"\n"
            ]

            csv.must_equal expected
        end

        it 'filters mysteries' do
            csv = @poi.csv([@mystery])
            csv.size.must_equal 0
        end

        it 'filters archived geocaches' do
            csv = @poi.csv([@archived])
            csv.size.must_equal 0
        end

        it 'filters deactivated geocaches' do
            csv = @poi.csv([@inactive])
            csv.size.must_equal 0
        end

        it 'allows filtering by type' do
            csv = @poi.csv(@simple, :type => :traditional)
            csv.must_equal ["-20.1234,10.1234,\"001 R T 1/2\nSimple Tradi\",\"HintHint\"\n"]
        end

        it 'replaces umlauts' do
            csv = @poi.csv([@umlauts])
            csv.must_equal ["-20.1234,10.1234,\"010 R T 1/2\nae oe ue AE OE UE ss\",\"ae oe ue AE OE UE ss\"\n"]
        end
        it 'replaces whitespace and quotes' do
            csv = @poi.csv([@whitespace])
            csv.must_equal ["-20.1234,10.1234,\"011 R T 1/2\nfoo bar baz\",\"foo bar baz\"\n"]
        end
    end

    describe 'gpx' do
        before do
            @empty = <<-EOS
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx
xmlns="http://www.topografix.com/GPX/1/1"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
version="1.1"
creator="cachecache">
</gpx>
EOS
            @empty.strip!
        end

        it 'generates a GPX of passed in geocaches' do
            gpx = @poi.gpx(@simple)
            expected = <<-EOS
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx
xmlns="http://www.topografix.com/GPX/1/1"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
version="1.1"
creator="cachecache">
<wpt lat="10.1234" lon="-20.1234">
<name>001 R T 1/2
Simple Tradi</name>
<cmt>HintHint</cmt>
<type>Geocache</type>
</wpt>
<wpt lat="10.1234" lon="-20.1234">
<name>002 S M 1/2
Simple Multi</name>
<cmt>HintHint</cmt>
<type>Geocache</type>
</wpt>
<wpt lat="10.1234" lon="-20.1234">
<name>003 S L 1/2
Simple Letterbox</name>
<cmt>HintHint</cmt>
<type>Geocache</type>
</wpt>
<wpt lat="10.1234" lon="-20.1234">
<name>005 S W 1/2
Simple Wherigo</name>
<cmt>HintHint</cmt>
<type>Geocache</type>
</wpt>
<wpt lat="10.1234" lon="-20.1234">
<name>006 S E 1/2
Simple Earthcache</name>
<cmt>HintHint</cmt>
<type>Geocache</type>
</wpt>
</gpx>
EOS
            expected.strip!
            gpx.must_equal expected
        end

        it 'filters mysteries' do
            gpx = @poi.gpx([@mystery])
            gpx.must_equal @empty
        end

        it 'filters archived geocaches' do
            gpx = @poi.gpx([@archived])
            gpx.must_equal @empty
        end

        it 'filters deactivated geocaches' do
            gpx = @poi.gpx([@inactive])
            gpx.must_equal @empty
        end

        it 'allows filtering by type' do
            expected = <<-EOS
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx
xmlns="http://www.topografix.com/GPX/1/1"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
version="1.1"
creator="cachecache">
<wpt lat="10.1234" lon="-20.1234">
<name>001 R T 1/2
Simple Tradi</name>
<cmt>HintHint</cmt>
<type>Geocache</type>
</wpt>
</gpx>
EOS
            expected.strip!
            gpx = @poi.gpx(@simple, :type => :traditional)
            gpx.must_equal expected
        end

        it 'replaces xml things' do
            expected = <<-EOS
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<gpx
xmlns="http://www.topografix.com/GPX/1/1"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
version="1.1"
creator="cachecache">
<wpt lat="10.1234" lon="-20.1234">
<name>012 R T 1/2
&lt;foo&gt; &amp; bar</name>
<cmt>&lt;foo&gt; &amp; bar</cmt>
<type>Geocache</type>
</wpt>
</gpx>
EOS
            expected.strip!
            gpx = @poi.gpx([@tags])
            gpx.must_equal expected
        end
    end
end

