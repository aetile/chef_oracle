# -*- mode: ruby; coding: utf-8; -*-

source 'https://rubygems.org'

ruby '2.3.1'

gem 'berkshelf', '3.2.3'
gem 'varia_model', '~> 0.4.0'
gem 'thor-foodcritic', git: 'https://github.com/reset/thor-foodcritic.git', ref: 'e38a99d539'
gem 'ridley', '= 4.1.1'
gem 'net-ssh', '= 4.1.0'

group :chef_gems do
  gem 'rvm', '~> 1.11'
end

group :test do
  gem 'chef', '12.5.1'
  gem 'chefspec', '4.2.0'
  gem 'thor', '0.19.1'
  gem 'foodcritic', '4.0.0'
  gem 'rubocop', '0.28.0'
end

group :integration do
  gem 'test-kitchen', '1.4.2'
  gem 'kitchen-vagrant', '0.19.0'
  gem 'serverspec', '2.8.0'
end
