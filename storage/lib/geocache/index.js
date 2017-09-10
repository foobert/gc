/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS207: Consider shorter variations of null checks
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const debug = require('debug')('gc:geocaches');
const refreshView = require('../db/refresh-view');
const upsert = require('../db/upsert');
const Promise = require('bluebird');
const QueryStream = require('./query-stream');

module.exports = function(db) {
    const STALE_REGEX = /^([<>]) (\d+) days?$/;
    const _mapRow = function(row, options) {
        if (options == null) { options = {}; }
        if (row == null) { return null; }
        if (options.withData == null) { options.withData = true; }
        if (options.withData) {
            return {
                Code: row.id,
                Name: row.name,
                Latitude: parseFloat(row.latitude),
                Longitude: parseFloat(row.longitude),
                Terrain: parseFloat(row.terrain),
                Difficulty: parseFloat(row.difficulty),
                Archived: row.archived,
                Available: row.available,
                CacheType: { GeocacheTypeId: parseInt(row.geocachetypeid)
            },
                ContainerType: { ContainerTypeName: row.containertypename
            },
                EncodedHints: row.encodedhints,
                UTCPlaceDate: row.utcplacedate.toISOString(),
                Owner: { UserName: row.username
            },
                meta: { updated: row.updated
            }
            };
        } else {
            return row.id;
        }
    };

    const _queryGeocaches = Promise.coroutine(function*(query, withData) {
        debug(`query ${JSON.stringify(query)}, ${withData}`);
        const [client, done] = Array.from(yield db.connect());
        let sql = db.select({tableAliasQuoteCharacter: '"'})
            .from('geocachesRel');

        sql = sql
            .field('upper(trim(id))', 'id')
            .field('updated');

        if (withData) {
            sql = sql
                .field('Name')
                .field('Latitude')
                .field('Longitude')
                .field('Archived')
                .field('Available')
                .field('EncodedHints')
                .field('Difficulty')
                .field('Terrain')
                .field('GeocacheTypeId')
                .field('ContainerTypeName')
                .field('UTCPlaceDate')
                .field('UserName');
        }

        switch (false) {
            case !STALE_REGEX.test(query.stale):
                var [_, direction, days] = Array.from(query.stale.match(STALE_REGEX));
                sql = sql.where(`age(updated) ${direction} interval '${days} days'`);
                break;
            case !['1', 1, true].includes(query.stale):
                break;
                // nothing to do, we want stale geocaches
            default:
                sql = sql.where("age(updated) < interval '3 days'");
        }

        if (query.maxAge != null) {
            sql = sql
                .where("age(UTCPlaceDate) < interval ?", `${query.maxAge} days`);
        }

        if (query.bounds != null) {
            const [lat0, lng0, lat1, lng1] = Array.from(query.bounds.map(x => parseFloat(x)));
            sql = sql
                .where("Latitude >= ?", lat0)
                .where("Latitude <= ?", lat1)
                .where("Longitude >= ?", lng0)
                .where("Longitude <= ?", lng1);
        }

        if (query.typeIds != null) {
            sql = sql
                .where('GeocacheTypeId IN ?', query.typeIds.map(x => parseInt(x)));
        }

        // query.attributeIds is currently not supported

        if (query.excludeFinds != null) {
            sql = sql
                .where('not ? = any(found)', query.excludeFinds[0]);
        }

        if (query.excludeDisabled === '1') {
            sql = sql
                .where('Archived = false')
                .where('Available = true');
        }

        if (query.orderBy != null) {
            sql = sql
                .order(query.orderBy, query.order !== 'desc');
        }

        const rows = client.query(sql.toString());
        const map = row => _mapRow(row, {withData});
        const geocacheStream = new QueryStream(rows, map, done);

        return geocacheStream;
    });

    return {
        getStream(query, withData) {
            return _queryGeocaches(query, withData);
        },

        get: Promise.coroutine(function*(id) {
            debug(`get ${id}`);
            const [client, done] = Array.from(yield db.connect());
            try {
                const sql = db.select()
                    .from('geocaches')
                    .field('updated')
                    .field('data')
                    .where('id = ?', id.trim().toLowerCase())
                    .toString();
                const result = yield client.queryAsync(sql);
                if (result.rowCount === 0) {
                    return null;
                } else {
                    const row = result.rows[0];
                    row.data.meta = {updated: row.updated};
                    return row.data;
                }
            } finally {
                done();
            }
        }),

        touch: Promise.coroutine(function*(id, date) {
            debug(`touch ${id}`);
            const [client, done] = Array.from(yield db.connect());
            try {
                const sql = db.update({numberedParameters: true})
                    .table('geocaches')
                    .set('updated', (date != null ? date.toISOString() : undefined) || 'now', {dontQuote: (date == null)})
                    .where('id = ?', id.trim().toLowerCase())
                    .toParam();
                const result = yield client.queryAsync(sql);
                return this.refresh();
            } finally {
                done();
            }
        }),

        upsert: Promise.coroutine(function*(data) {
            debug(`upsert ${(data.Code != null ? data.Code.toLowerCase() : undefined)}`);
            yield upsert(db, 'geocaches', data);
            return this.refresh();
        }),

        delete: Promise.coroutine(function*(id) {
            debug(`delete ${id}`);
            const [client, done] = Array.from(yield db.connect());
            try {
                const sql = db.delete()
                        .from('geocaches')
                        .where('id = ?', id.trim().toLowerCase())
                        .toString();
                yield client.queryAsync(sql);
                return this.refresh();
            } finally {
                done();
            }
        }),

        deleteAll: Promise.coroutine(function*() {
            debug('delete all');
            const [client, done] = Array.from(yield db.connect());
            try {
                const sql = db.delete()
                    .from('geocaches')
                    .toString();
                yield client.queryAsync(sql);
                return this.refresh();
            } finally {
                done();
            }
        }),

        refresh: refreshView.debounce(db, 'geocachesRel', 30000, debug),
        forceRefresh() {
            return refreshView.refresh(db, 'geocachesRel', debug);
        }
    };
};
