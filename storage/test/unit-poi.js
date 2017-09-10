/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const {expect} = require('chai');
const poi = require('../lib/poi/format');

describe('poi', function() {
    let gc = null;

    const sizes = ['Other', 'Not Specified', 'Micro', 'Small', 'Regular', 'Large'];
    const types = [{
        id: 2,
        name: 'Traditional'
    }
    , {
        id: 3,
        name: 'Multi'
    }
    , {
        id: 5,
        name: 'Letterbox'
    }
    , {
        id: 11,
        name: 'Wherigo'
    }
    , {
        id: 137,
        name: 'Earth Cache'
    }
    ];

    beforeEach(() =>
        gc = {
            Code: 'GC1BAZ8',
            Name: 'this is the name',
            Difficulty: 1,
            Terrain: 1,
            ContainerType: { ContainerTypeName: 'Micro'
        },
            CacheType: { GeocacheTypeId: 2
        },
            EncodedHints: 'this is a hint',
            meta: { updated: new Date()
        }
        }
    );

    describe('title', function() {
        sizes.forEach(size =>
            it(`should contain size for ${size}`, function() {
                gc.ContainerType.ContainerTypeName = size;
                const expected = size[0].toUpperCase();

                const title = poi.title(gc);
                return expect(title).to.match(new RegExp(`^${expected}`));
            })
        );

        types.forEach(({id, name}) =>
            it(`should contain type for ${name}`, function() {
                gc.CacheType.GeocacheTypeId = id;
                const expected = name[0].toUpperCase();

                const title = poi.title(gc);
                return expect(title).to.match(new RegExp(`^.${expected}`));
            })
        );

        it('should use a question mark for unknown sizes', function() {
            gc.CacheType.GeocacheTypeId = 99999;
            const title = poi.title(gc);
            return expect(title).to.match(/^.\?/);
        });

        it('should contain the skill', function() {
            gc.Difficulty = 1;
            gc.Terrain = 1;
            const title = poi.title(gc);
            return expect(title).to.contain('1.0/1.0');
        });

        it('should support half difficulties', function() {
            gc.Difficulty = 1.5;
            const title = poi.title(gc);
            return expect(title).to.contain('1.5/1.0');
        });

        it('should support half terrains', function() {
            gc.Terrain = 1.5;
            const title = poi.title(gc);
            return expect(title).to.contain('1.0/1.5');
        });

        return it('should contain the updated date', function() {
            gc.meta.updated = new Date('2015-01-02T06:00:00Z');
            const title = poi.title(gc);
            return expect(title).to.contain('0102');
        });
    });

    return describe('description', function() {
        it('should be limited to 100 characters', function() {
            let s = '';
            for (let i = 0; i < 100; i++) {
                s += i % 10;
            }
            gc.EncodedHints = s;
            const description = poi.description(gc);
            return expect(description).to.have.length(100);
        });

        describe('GC code', function() {
            it('should contain the GC code (without GC)', function() {
                gc.Code = 'GCAB123';
                const description = poi.description(gc);
                return expect(description).to.match(/^AB123 /);
            });

            return it('should contain the GC code for short GC numbers', function() {
                gc.Code = 'GC12';
                const description = poi.description(gc);
                return expect(description).to.match(/^12 /);
            });
        });

        describe('Name', function() {
            it('should contain the name followed by a newline', function() {
                gc.Name = 'some name';
                const description = poi.description(gc);
                return expect(description).to.match(new RegExp(' some name\\n'));
            });

            it('should replace umlauts', function() {
                gc.Name = 'üöäÜÖÄß';
                const description = poi.description(gc);
                return expect(description).to.contain('ueoeaeUEOEAEss');
            });

            it('should squash multiple spaces', function() {
                gc.Name = 'foo  bar    baz';
                const description = poi.description(gc);
                return expect(description).to.contain('foo bar baz\n');
            });

            it('should trim the name', function() {
                gc.Code = 'GCAB123';
                gc.Name = '    foo    ';
                const description = poi.description(gc);
                return expect(description).to.contain('AB123 foo\n');
            });

            return it('should filter strange symbols', function() {
                gc.Name = 'foo^😏àbar';
                const description = poi.description(gc);
                return expect(description).to.contain('foobar\n');
            });
        });

        return describe('Hint', function() {
            it('should include the hint', function() {
                gc.EncodedHints = 'hinttext';
                const description = poi.description(gc);
                return expect(description).to.contain('\nhinttext');
            });

            return it('should filter strange symbols', function() {
                gc.EncodedHints = 'foo^😏àbar';
                const description = poi.description(gc);
                return expect(description).to.contain('\nfoobar');
            });
        });
    });
});
