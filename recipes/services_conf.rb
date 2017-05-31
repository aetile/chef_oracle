# -*- mode: ruby; coding: utf-8; -*-

# NTP service needs to run with -x option for RAC node
template '/etc/sysconfig/ntpd' do
  source 'ntpd.erb'
  owner node['chef_oracle']['superuser']
  group node['chef_oracle']['superuser']
  mode '0644'
  only_if { node.role?('oracle_rac') }
end

# Install local DNS service for RAC node
yum_package 'bind' do
  ignore_failure false
  action :install
  only_if { node.role?('oracle_rac') }
end

# Install SSH service for RAC node
yum_package 'openssh-server' do
  ignore_failure false
  action :install
  only_if { node.role?('oracle_rac') }
end

# Configure SSH equivalence for RAC nodes
