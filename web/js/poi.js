window.POI = (function() {

    var generatePoi = function(username, type, format, cb) {
        _download('http://api.gc.funkenburg.net/poi.' + format + '?exclude=' + username + '&type=' + type, cb);
    };

    var downloadImage = function(type, cb) {
        _download(document.URL + 'img/' + type + '.bmp', cb);
    };

    var _download = function(url, cb) {
        var xhr = new XMLHttpRequest();
        xhr.onreadystatechange = function() {
            if (this.readyState == 4) {
                if (this.status == 200) {
                    cb(null, this.response);
                } else {
                    cb(new Error("Download of " + url + " failed: " + this.status), null);
                }
            }
        };

        xhr.open('GET', url);
        xhr.responseType = 'arraybuffer';
        xhr.send();
    };


    return {generate: generatePoi, downloadImage: downloadImage};
})();
