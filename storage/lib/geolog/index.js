const debug = require('debug')('gc:geologs');
const moment = require('moment');

function getId(data) {
    if (typeof data === 'string') {
        return data.toLowerCase();
    }
    return data
        && data.Code
        && data.Code.toLowerCase();
}

function getUsername(data) {
    return data
        && data.Finder
        && data.Finder.UserName
        && data.Finder.UserName.toLowerCase();
}

function getVisitDate(data) {
    return data && moment(data.VisitDate).toDate();
}

function getCode(data) {
    return data && data.CacheCode;
}

module.exports = function(db) {
    const geologs = db.collection('geologs');
    const founds = db.collection('founds');
    return {
        async upsert(data) {
            const id = getId(data);
            const username = getUsername(data);
            const visitDate = getVisitDate(data);
            const code = getCode(data);

            debug('Upsert', id);
            const result = await geologs.update(
                {_id: id},
                {_id: id, username, visitDate, data},
                {upsert: true}
            );
            const found = await founds.update(
                {_id: username},
                {$addToSet: {geocaches: code}},
                {upsert: true}
            );
            debug(`Upsert ${id}:`, result.result.nModified);
        },

        async latest(username) {
            debug('Latest', username);
            let select = {};
            if (username != null) {
                select.username = {$eq: username.toLowerCase()};
            }

            const cursor = await geologs.find(select, {_id: 1}).limit(1).sort({visitDate: -1});
            const doc = await cursor.hasNext() ? await cursor.next() : null;
            debug(`Latest ${username}`, doc);
            return doc && doc._id.toUpperCase();
        },

        async deleteAll() {
            debug('Delete all');
            const result = await geologs.deleteMany({});
            await founds.deleteMany({});
            debug('Delete all', result.result);
        },
    };
}
