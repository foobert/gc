#!/bin/bash
docker run --rm -v $PWD:/usr/src/app iojs:onbuild npm install "$@" --save
