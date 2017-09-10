/*
 * decaffeinate suggestions:
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const debug = require('debug')('gc:db');
const pg = require('pg');
const squel = require('squel').useFlavour('postgres');
const Promise = require('bluebird');
Promise.promisifyAll(pg);

process.on('SIGINT', function() {
    pg.end();
    return process.exit();
});

module.exports = function(options) {
    const migrate = require('./migrate')();
    return {
        database: options.database,

        select: squel.select,
        insert: squel.insert,
        update: squel.update,
        delete: squel.delete,
        connect: Promise.coroutine(function*(database) {
            let err;
            let tries = 5;
            while (tries-- > 0) {
                try {
                    const o = JSON.parse(JSON.stringify(options));
                    if (database != null) { o.database = database; }
                    return yield pg.connectAsync(o);
                } catch (error) {
                    err = error;
                    yield Promise.delay(500);
                }
            }
            debug(`connection to database failed: ${err}`);
            throw err;
        }),

        up: Promise.coroutine(function*() {
            yield migrate.up(this, [
                'CREATE TABLE geocaches (id char(8) PRIMARY KEY, updated timestamp with time zone NOT NULL, data jsonb)',
                'CREATE TABLE tokens (id uuid UNIQUE)'
            ]);
            yield migrate.up(this, [
                // TODO need to work with dates that don't use 10 numbers, see
                // UTCCreateDate, VisitDate et al.
                'CREATE TABLE logs (id char(8) PRIMARY KEY, updated timestamp with time zone NOT NULL, data jsonb)',
                `\
CREATE VIEW logsRel AS
        SELECT id
             , updated
             , data->>'CacheCode' as cachecode
             , data->'Finder'->>'UserName' as username
             , data->'LogType'->>'WptLogTypeId' as logtype
             , (date 'epoch' + (substring(data->>'UTCCreateDate' from 7 for 10)::numeric * interval '1 second')) as createdate
             , (date 'epoch' + (substring(data->>'VisitDate' from 7 for 10)::numeric - substring(data->>'VisitDate' from 21 for 2)::numeric * 3600) * interval '1 second') as VisitDate
        FROM logs\
`
            ]);
            yield migrate.up(this, [
                `\
CREATE MATERIALIZED VIEW founds AS
        SELECT
            c.id,
            array(SELECT DISTINCT l.username FROM logsRel l WHERE lower(l.cachecode) = c.id AND l.logtype = '2') AS usernames
        FROM geocaches c\
`
            ]);
            return yield migrate.up(this, [
                // TODO need to work with dates that don't use 10 numbers, see
                // UTCCreateDate, VisitDate et al.
                `\
CREATE MATERIALIZED VIEW geocachesRel AS
        SELECT
            c.id,
            c.updated as updated,
            (c.data->>'Name') as Name,
            (c.data->>'Latitude')::numeric as Latitude,
            (c.data->>'Longitude')::numeric as Longitude,
            (c.data->'CacheType'->>'GeocacheTypeId')::numeric as GeocacheTypeId,
            c.data->'ContainerType'->>'ContainerTypeName' as ContainerTypeName,
            (c.data->>'Difficulty')::numeric as Difficulty,
            (c.data->>'Terrain')::numeric as Terrain,
            c.data->>'EncodedHints' as EncodedHints,
            (c.data->>'Archived')::bool as Archived,
            (c.data->>'Available')::bool as Available,
            (date 'epoch' + (substring(c.data->>'UTCPlaceDate' from 7 for 10)::numeric - substring(c.data->>'UTCPlaceDate' from 21 for 2)::numeric * 3600) * interval '1 second') as UTCPlaceDate,
            ARRAY(SELECT DISTINCT data->'Finder'->>'UserName' FROM logs l WHERE lower(l.data->>'CacheCode') = c.id AND l.data->'LogType'->>'WptLogTypeId' = '2') as found,
            (c.data->'Owner'->>'UserName') as UserName
        FROM geocaches c\
`
            ]);})
    };
};

