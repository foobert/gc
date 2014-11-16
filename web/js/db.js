window.DB = (function() {
    var server = "http://gc.funkenburg.net/api/";
    //server = "http://localhost:5984/gc";

    var check = function(cb) {
        $.ajax(server,
        {
            success: function (xhdr, data) { cb(null); },
            error: function (xhdr, err) { cb(err); }
        });
    }

    var getFoundLogs = function(username, cb) {
        if (username == null || username == undefined || username == "") {
            cb([]);
        } else {
        $.getJSON(server + "/_design/frontend/_view/foundLogs?startkey=[\"" + username + "\"]", function (data) {
            var found = data.rows.map(function(x) { return x.value; });
            cb(found);
            });
        }
    }

    var getGeocaches = function(cb) {
        $.getJSON(server + "/_design/frontend/_view/full", function (data) {
            data.rows.forEach(function(row) {
                cb(row.value);
            });
            cb("done");
        });
    }

    var getLastLogs = function(username, cb) {
        if (username == null || username == undefined || username == "") {
            cb([]);
        } else {
            var url = server + "/_design/frontend/_view/latestLogs?startkey=[\"" + username + "\",{}]&endkey=[\"" + username + "\"]&descending=true&limit=5";
            $.getJSON(url, function (data) {
                var logs = data.rows.map(function(x) { return x.value; });
                cb(logs);
                });
        }
    }

    return {
        getFoundLogs: getFoundLogs,
        getGeocaches: getGeocaches,
        getLastLogs: getLastLogs,
        server: server,
        check: check
    };
})();
