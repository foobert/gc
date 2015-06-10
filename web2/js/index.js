require('../css/index.css');
require('jquery');

$(function() {
    $('.ui.checkbox').checkbox();
    $('.ui.radio.checkbox').checkbox();

    $('.submit.button').click(function() {
        $('.form').addClass('loading');
        var files = [
            {url: 'https://gc.funkenburg.net/api/poi.csv?type=3', name: 'multi.csv'},
            {url: 'http://gc.funkenburg.net/api/poi.csv?type=2', name: 'tradi.csv'}
        ];
        var JSZip = require('jszip');
        var zip = new JSZip();
        var zipFolder = zip.folder('poi');
        var h = function(name, data) {
            if (data != null) {
                zipFolder.file(name, data);
            }
            if (files.length === 0) {
                var zipBlob = zip.generate({type: 'blob'});
                var saveAs = require('FileSaver');
                saveAs(zipBlob, 'poi.zip');
                $('.form').removeClass('loading');
            } else {
                var next = files.shift();
                $.get(next.url)
                    .done(function(data) { h(next.name, data); })
                    .fail(function() {
                        $('.form').removeClass('loading').addClass('error');
                    });
            }
        };
        h();
    });
});
