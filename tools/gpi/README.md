# Overview

This directory contains various scripts to automatically upload POI files to a Garmin eTrex HCx.

## Installation

NB This requires root permissions

 - Edit poi-udev.sh and adopt it to your needs (see below)
 - Copy poi-udev.sh to /usr/local/bin
 - Copy poi.sh to /usr/local/bin (unless you want to use a docker container for it)
 - Copy garmin-poi.rules to /etc/udev/rules.d

### poi-udev.sh

This is the script that will be called by udev. It's job is to mount the block device, call poi.sh and clean up afterwards.

If you don't want to use a docker container, remove the docker line and uncomment the call to poi.sh.

### poi.sh

poi.sh does all the work of downloading the POIs and converting them. Because it depends on gpsbabel and wget, it can also be run inside a docker
container. See Dockerfile.
