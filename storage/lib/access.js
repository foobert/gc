const uuid = require('uuid');

module.exports = db =>
    ({
        init: async function() {
            return (await this.getToken()) || (await this.addToken());
        },

        check: async function(token) {
            if (!token) {
                return false;
            }
            const result = db.find({_id: token}).limit(1).project({_id: 1});
            return await result.hasNext();
        },

        addToken: async function() {
            const token = uuid.v4();
            await db.insert({_id: token});
            return token;
        },

        getToken: async function() {
            const result = await db.find({}).limit(1).project({_id:1});
            if (await result.hasNext()) {
                const doc = await result.next();
                return await doc._id;
            } else {
                return null;
            }
        }
    })
;
