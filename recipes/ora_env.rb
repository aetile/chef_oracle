# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_chef_oracle
# Recipe:: configure oracle environment
#

# Create users and groups
group node['chef_oracle']['group'] do
  gid node['chef_oracle']['gid']
  action :create
end

user node['chef_oracle']['user'] do
  uid node['chef_oracle']['uid']
  gid node['chef_oracle']['gid']
  home node['chef_oracle']['home']
  shell node['chef_oracle']['shell']
  comment 'Oracle Administrator'
  manage_home true
  action :create
end

node['chef_oracle']['extra_groups'].each do |grp|
  group grp['name'] do
    gid grp['id']
    members node['chef_oracle']['user']
    append true
    action :create
  end
end

# Create app directory
directory node['chef_oracle']['app_dir'] do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

# Create Oracle software directory tree
node['chef_oracle']['ora_dir_tree'].each do |ora_dir|
  directory ora_dir do
    owner node['chef_oracle']['user']
    group node['chef_oracle']['group']
    #recursive true
    mode '0755'
    action :create
  end
end

directory node['chef_oracle']['ora_inv_dir'] do
  owner node['chef_oracle']['user']
  group node['chef_oracle']['group']
  #recursive true
  mode '0755'
  action :create
end

node['chef_oracle']['rman_dir'].each do |rman_dir|
  directory rman_dir do
    owner node['chef_oracle']['user']
    group node['chef_oracle']['group']
    recursive true
    mode '0755'
    action :create
  end
end

# Set Oracle user and root environment variables
template node['chef_oracle']['profile'] do
  source 'bash_profile.erb'
  owner node['chef_oracle']['user']
  group node['chef_oracle']['group']
  mode '0755'
  variables(
    oracle_base: node['chef_oracle']['ora_base_dir'],
    oracle_home: node['chef_oracle']['db']['home_dir'],
    grid_home: node['chef_oracle']['db']['grid_dir'],
    db_sid: node['chef_oracle']['db']['sid']
    )
end

template node['chef_oracle']['root_profile'] do
  source 'ora_root.sh'
  owner 'root'
  group 'root'
  mode '0755'
  variables(
    oracle_base: node['chef_oracle']['ora_base_dir'],
    oracle_home: node['chef_oracle']['db']['home_dir'],
    grid_home: node['chef_oracle']['db']['grid_dir'],
    db_sid: node['chef_oracle']['db']['sid']
    )
end
