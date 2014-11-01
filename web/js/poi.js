window.POI = (function() {

    var generatePoi = function(username, type, near, format, cb) {
        _download('http://localhost:4567/poi.' + format + '?exclude=' + username + '&type=' + type + '&near=' + near, cb);
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
