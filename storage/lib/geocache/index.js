const debug = require('debug')('gc:geocaches');
const moment = require('moment');
const queryGeocaches = require('./query');

function getId(data) {
    if (!data) { return null; }
    if (typeof data === 'string') {
        return data.toLowerCase();
    }
    return data.Code && data.Code.toLowerCase() || null;
}

module.exports = function(db) {
    const STALE_REGEX = /^([<>]) (\d+) days?$/;

    return {
        async getStream(query, withData) {
            debug('GetStream', query, withData);
            return queryGeocaches(db, query, withData);
        },

        async get(id) {
            id = getId(id);
            debug('Get', id);
            const result = await db.find({_id: id}).limit(1).project({updated: 1, data: 1});
            if (!await result.hasNext()) {
                debug(`get ${id}: null`);
                return null;
            }
            const doc = await result.next();
            debug(`Get ${id}: last updated ${moment(doc.updated).fromNow()}`);
            doc.data.meta = {updated: doc.updated};
            return doc.data;
        },

        async touch(id) {
            debug('Touch', id);
            const result = await db.update(
                {_id: id},
                {$currentDate: {updated: 'timestamp'}},
                {upsert: false}
            );
            debug(`Touch ${id}:`, result.result);
        },

        async upsert(data) {
            const id = getId(data);
            if (!id) {
                throw new Error('data has no Code');
            }
            debug('Upsert', id);
            const doc = {
                updated: new Date(),
                data: data,
                coord: {type: 'Point', coordinates: [data.Longitude, data.Latitude]},
                placed: new Date(parseInt(data.UTCPlaceDate.substr(6))),
            };
            const result = await db.update({_id: id}, doc, {upsert: true});
            debug(`Upsert ${id}:`, result.result);
        },

        async delete(id) {
            debug('Delete', id);
            const result = await db.deleteOne({_id: id});
            debug(`Delete ${id}:`, result.result);
        },

        async deleteAll() {
            debug('Delete all');
            const result = await db.deleteMany({});
            debug('Deleted all:', result.result);
        },

        refresh() {},
        forceRefresh() {},
    };
};
