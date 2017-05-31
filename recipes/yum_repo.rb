# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_oracle
# Recipe:: configure_yum_repo
#

# Configure local yum repo
case node['platform']
when 'redhat'
  #include_recipe 'yum-epel'

  yum_repository 'local' do
    description 'Local RHEL repo'
    baseurl node['chef_oracle']['rpm_repo_url']
    gpgcheck false
    make_cache false
    enabled true
    action [:delete, :create]
  end

  # Configure local ASMLib repo
  yum_repository 'asmlib' do
    description 'Local ASMLib repo'
    baseurl node['chef_oracle']['asm_repo_url']
    gpgcheck false
    make_cache false
    enabled true
    action [:delete, :create]
  end
end
