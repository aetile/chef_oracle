# -*- mode: ruby; coding: utf-8; -*-

# DNS service is supposed to listen on cluster node mgmt IP from rac databag
bag_item = node['chef_oracle']['db']['rac']['databag']
rac_bag = data_bag_item("db_params", "rac")

fail 'Unable to load the db_params:rac databag.' unless rac_bag

node.override['resolver']['search'] = rac_bag['resolver']['search']
node.override['resolver']['nameservers'] = rac_bag['resolver']['nameservers']
node.override['resolver']['options'] = rac_bag ['resolver']['options']

include_recipe 'resolver::default'
