# GC

Geocaching Tools and POI Generation


## What?

This can be used to store geocache information retrieved from a popular
geocaching website. The idea is to save some data locally and then do
interesting things with it.

One example would be to automatically generate a POI file for GPS receivers.

## Architecture

The repository constists of three parts:

 - app
 - web
 - db

### App

This is the application server. It provides a RESTful API for the web client. It
also contains a tool to download geocache information and store them in the
database. This should in theory also be done over the web API, but not yet.

### Web

This is a very simple webclient which talks to the app server. There are not
many endpoints yet and it's all very hacky.

### DB

The database is a plain RethinkDB. Nothing fancy.

## Development

To develop on this project you can user the provided docker files or just
install all dependencies on your dev system.

### App

It's a ruby based web server. To get the dependencies run
`bundler install --path vendor/bundle`. Afterwars start the app server with
`app/bin/cachecache serve`. It needs at least an environment variable pointing
to the database.

### Web

The website uses Jekyll. Just run `jekyll serve --watch` inside the web
directory.

### DB

Nothing to be done here. Just run RethinkDB.
