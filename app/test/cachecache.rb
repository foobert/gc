$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'bundler/setup'

require './test/cachecache/geocaching.rb'
require './test/cachecache/poi.rb'
require './test/cachecache/server.rb'
require './test/cachecache/timeParser.rb'
