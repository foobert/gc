{expect} = require 'chai'
poi = require '../lib/poi/format'

describe 'poi', ->
    gc = null

    sizes = ['Other', 'Not Specified', 'Micro', 'Small', 'Regular', 'Large']
    types = [
        id: 2
        name: 'Traditional'
    ,
        id: 3
        name: 'Multi'
    ,
        id: 5
        name: 'Letterbox'
    ,
        id: 11
        name: 'Wherigo'
    ,
        id: 137
        name: 'Earth Cache'
    ]

    beforeEach ->
        gc =
            Code: 'GC1BAZ8'
            Name: 'this is the name'
            Difficulty: 1
            Terrain: 1
            ContainerType: ContainerTypeName: 'Micro'
            CacheType: GeocacheTypeId: 2
            EncodedHints: 'this is a hint'
            meta: updated: new Date()

    describe 'title', ->
        sizes.forEach (size) ->
            it "should contain size for #{size}", ->
                gc.ContainerType.ContainerTypeName = size
                expected = size[0].toUpperCase()

                title = poi.title gc
                expect(title).to.match new RegExp "^#{expected}"

        types.forEach ({id, name}) ->
            it "should contain type for #{name}", ->
                gc.CacheType.GeocacheTypeId = id
                expected = name[0].toUpperCase()

                title = poi.title gc
                expect(title).to.match new RegExp "^.#{expected}"

        it 'should use a question mark for unknown sizes', ->
            gc.CacheType.GeocacheTypeId = 99999
            title = poi.title gc
            expect(title).to.match /^.\?/

        it 'should contain the skill', ->
            gc.Difficulty = 1
            gc.Terrain = 1
            title = poi.title gc
            expect(title).to.contain '1.0/1.0'

        it 'should support half difficulties', ->
            gc.Difficulty = 1.5
            title = poi.title gc
            expect(title).to.contain '1.5/1.0'

        it 'should support half terrains', ->
            gc.Terrain = 1.5
            title = poi.title gc
            expect(title).to.contain '1.0/1.5'

        it 'should contain the updated date', ->
            gc.meta.updated = new Date('2015-01-02T06:00:00Z')
            title = poi.title gc
            expect(title).to.contain '0102'

    describe 'description', ->
        it 'should be limited to 100 characters', ->
            s = ''
            for i in [0...100]
                s += i % 10
            gc.EncodedHints = s
            description = poi.description gc
            expect(description).to.have.length 100

        describe 'GC code', ->
            it 'should contain the GC code (without GC)', ->
                gc.Code = 'GCAB123'
                description = poi.description gc
                expect(description).to.match /^AB123 /

            it 'should contain the GC code for short GC numbers', ->
                gc.Code = 'GC12'
                description = poi.description gc
                expect(description).to.match /^12 /

        describe 'Name', ->
            it 'should contain the name followed by a newline', ->
                gc.Name = 'some name'
                description = poi.description gc
                expect(description).to.match new RegExp ' some name\\n'

            it 'should replace umlauts', ->
                gc.Name = 'üöäÜÖÄß'
                description = poi.description gc
                expect(description).to.contain 'ueoeaeUEOEAEss'

            it 'should squash multiple spaces', ->
                gc.Name = 'foo  bar    baz'
                description = poi.description gc
                expect(description).to.contain 'foo bar baz\n'

            it 'should trim the name', ->
                gc.Code = 'GCAB123'
                gc.Name = '    foo    '
                description = poi.description gc
                expect(description).to.contain 'AB123 foo\n'

            it 'should filter strange symbols', ->
                gc.Name = 'foo^😏àbar'
                description = poi.description gc
                expect(description).to.contain 'foobar\n'

        describe 'Hint', ->
            it 'should include the hint', ->
                gc.EncodedHints = 'hinttext'
                description = poi.description gc
                expect(description).to.contain '\nhinttext'

            it 'should filter strange symbols', ->
                gc.EncodedHints = 'foo^😏àbar'
                description = poi.description gc
                expect(description).to.contain '\nfoobar'
