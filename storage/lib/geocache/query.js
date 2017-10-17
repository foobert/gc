const debug = require('debug')('gc:geocaches:query');
const filter = require('stream-filter');

module.exports = async function queryGeocaches(db, query, withData) {
    const projection = project(query, withData);
    const selection = select(query);
    const transformation = transform(withData);

    debug('Query', query, withData);
    debug('Selection', selection);
    debug('Projection', projection);

    const cursor = await db.find(selection).project(projection);
    const stream = cursor.stream({transform: transformation});

    const excludeFinds = await lookupFinds(db, query);
    if (excludeFinds.length == 0) {
        return stream;
    } else {
        return stream.pipe(filter.obj(doc => excludeFinds.include(doc.Code)));
    }

    /*
        if (query.excludeFinds != null) {
            sql = sql
                .where('not ? = any(found)', query.excludeFinds[0]);
        }

        if (query.orderBy != null) {
            sql = sql
                .order(query.orderBy, query.order !== 'desc');
        }
        */
}

function truthy(param) {
    return ['1', 1, true].includes(param);
}

function filterStale(query) {
    if (truthy(query.stale)) {
        return;
    }

    // filter stale geocaches, i.e. last update older than three days
    const threeDaysAgo = new Date();
    threeDaysAgo.setDate(threeDaysAgo.getDate() - 3)
    return {
        updated: {$gte: threeDaysAgo},
    }
}

function filterTypeId(query) {
    if (query.typeIds != null && query.typeIds.length > 0) {
        const typeIds = query.typeIds.map(x => parseInt(x));
        return {'data.CacheType.GeocacheTypeId': {$in: typeIds}};
    }
}

function filterBounds(query) {
    if (query.bounds != null) {
        const [lat0, lng0, lat1, lng1] = Array.from(query.bounds.map(x => parseFloat(x)));
        return {coord: {$geoWithin: {$box: [[lat0, lng0], [lat1, lng1]]}}};
    }
}

function filterDisabled(query) {
    if (truthy(query.excludeDisabled)) {
        return {
            'data.Archived': false,
            'data.Available': true,
        }
    }
}

function filterMaxAge(query) {
    if (query.maxAge != null) {
        const days = parseInt(query.maxAge);
        const xDaysAgo = new Date();
        xDaysAgo.setDate(xDaysAgo.getDate() - days);
        return {placed: {$gte: xDaysAgo}};
    }
}

function project(query, withData) {
    let projection = {
        _id: 1,
        updated: 1,
    };
    if (withData) { projection.data = 1; }
    return projection;
}

function select(query) {
    const filters = [
        filterStale,
        filterTypeId,
        filterBounds,
        filterDisabled,
        filterMaxAge,
    ];
    const selection = filters.reduce((s, u) => Object.assign(s, u(query)), {});
    return selection;
}

async function lookupFinds(db, query) {
    if (query.excludeFinds == null) {
        return [];
    }
    let exclude;
    if (typeof query.excludeFinds === 'string') {
        exclude = [query.excludeFinds];
    } else {
        exclude = query.excludeFinds;
    }
    const result = await db.collection('geologs')
        .find({username: {$in: exclude}}, {'data.CacheCode': 1});
    return result.toArray();
}

function transform(withData) {
    if (withData) {
        return (doc) => doc.data;
    } else {
        return (doc) => doc._id.toUpperCase();
    }
}
