module.exports =
    url: (path) ->
        base = localStorage.getItem('server') or 'https://gc.funkenburg.net/api'
        if path?
            base + path
        else
            base
