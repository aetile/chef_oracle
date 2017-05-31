# -*- mode: ruby; coding: utf-8; -*-

require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'

at_exit { ChefSpec::Coverage.report! }
