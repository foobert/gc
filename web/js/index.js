var downloadObjects = [];

$("#download").click(function() {
    downloadObjects.forEach(function(a) {
        saveAs(a.blob, a.filename);
    });

    $("#dialog").modal("hide");
});

$("#generate").click(function() {
    var btn = $(this);
    btn.button("loading");

    var username = $("#username").val();
    var selectedTypes = $("input.type[type='checkbox']:checked").map(function(i, c) { return c.value; }).toArray();
    var downloadImages = document.getElementById("add-icons").checked;
    var format = document.getElementById('gpx').checked ? 'gpx' : 'csv';
    var near = $("#near").val();

    $("#dialog").modal();
    btn.button("reset");

    var todo = selectedTypes.length;
    var zip = new JSZip();

    var pushDownloadObject;
    var closeDownloadObject;

    if (downloadImages || selectedTypes.length > 1) {
        var zipFolder = zip.folder("poi");
        pushDownloadObject = function(name, arraybuffer) {
            zipFolder.file(name, arraybuffer);
        };
        closeDownloadObject = function() {
            var zippedBlob = zip.generate({type: 'blob'});
            downloadObjects.push({blob: zippedBlob, filename: 'poi.zip'});
        };
    } else {
        pushDownloadObject = function(name, arraybuffer) {
            downloadObjects.push({blob: new Blob([arraybuffer]), filename: name});
        };
        closeDownloadObject = function() {
        };
    }


    selectedTypes.forEach(function(type) {
        console.log("Downloading POIs of type " + type);
        $("#status-types").append("<li id='status-type-" + type + "'>Generating " + type + "</li>");
        $("#status-text").text("Generating POIs");

        var done = function() {
            $("#status-type-" + type).remove();
            todo--;
            if (todo === 0) {
                console.log('Enabling download link');
                closeDownloadObject();
                $("#status-text").text("Download ready.");
                $("#download").removeAttr('disabled');
            }
        };

        POI.generate(username, type, near, format, function(err, data) {
            if (err) throw err;
            pushDownloadObject(type + '.' + format, data);
            console.log("Downloaded POIs of type " + type);

            if (downloadImages) {
                POI.downloadImage(type, function(err, data) {
                    if (err) throw err;
                    pushDownloadObject(type + '.bmp', data);
                    done();
                });
            } else {
                done();
            }
        });
    });
});

$("#server").text("Connecting to " + DB.server);
DB.check(function(res) {
    if (res == null) {
        $("#server").text("Connected to " + DB.server);
    } else {
        $("#server").text("Failed to connect to server: " + res);
    }
});
