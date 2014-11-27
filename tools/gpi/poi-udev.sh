#!/bin/bash
# This script is meant to be run from udev
# Usage: poi-udev.sh sdX
# where sdX is the device corresponding to you Garmin mass storage
set -e

if [ -z $1 ]
    echo "Usage: $0 sdX" >&2
    exit 1
fi

dev=/dev/$1
mnt=$(mktemp -d)
logger "Mounting $dev as $mnt"
mount $dev $mnt -o fmask=111,dmask=000 || exit
# Change poi.sh invocation here if you need to
# See poi.sh for additional options.
docker run --rm=true -v $mnt/Garmin/Poi:/data foobert/gpi /data
# Can also be used directly without docker:
# /usr/local/bin/poi.sh $mnt/Garmin/Poi
umount $dev
rm -r $mnt
