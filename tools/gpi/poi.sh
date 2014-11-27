#!/bin/bash

function poi {
    local typeId=$1
    #echo Generating POIs for type $typeId

    local iconId=""
    case $typeId in
    2) iconId=traditional;;
    3) iconId=multi;;
    5) iconId=letterbox;;
    11) iconId=webcam;;
    137) iconId=earth;;
    *)
        echo "Invalid type id ${typeId}" >&2
        exit
        ;;
    esac

    local iconUrl=${server}/img/${iconId}.bmp

    wget --quiet $iconUrl
    wget --quiet -O ${typeId}.gpx "${server}/api/poi.gpx?typeIds[]=${typeId}&excludeFinds[]=${username}&stale=0&excludeDisabled=1"
    gpsbabel -i gpx -f ${typeId}.gpx -o garmin_gpi,bitmap=${iconId}.bmp,sleep=1 -F ${typeId}.gpi
    cp --no-preserve=all ${typeId}.gpi "${target}"
}

function tts {
    hash say 2>/dev/null && say $@ && return
    hash festival 2>/dev/null && echo $@ | festival --tts
}

function cleanup {
    [ -d "$tmp" ] && rm -r "$tmp"
    [ -d "$tmpMount" ] && umount "$tmpMount"
}

function usage {
    echo "Usage: $0 [options] <path>"
    echo "  -s the URL of the server, defaults to http://gc.funkenburg.net"
    echo "  -u the username to exclude logs from, defaults to none"
}

OPTIND=1
server=http://gc.funkenburg.net
username=""
target=""

while getopts "h?u:s:" opt; do
    case "$opt" in
    h|\?)
        usage
        exit
        ;;
    u)
        username=$OPTARG
        ;;
    s)
        server=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

target=$1
if [ -z "$target" ]; then
    usage;
    exit 1
fi

if [ ! -d "$target" ]; then
    echo "$target must be an existing directory">&2
    exit 1
fi

trap cleanup EXIT

tmp=$(mktemp -d)
cd $tmp

tts "Generating P O I files"
poi 2
poi 3
poi 5
poi 11
poi 137
tts "Happy Caching!"
