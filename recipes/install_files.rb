# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_oracle
# Recipe:: install_files
#

# Unzip Oracle install files
yum_package 'unzip' do
  action :install
end

# Unzip Oracle install files
node['chef_oracle']['db']['install_files'].each do |file|
  remote_file file['name'] do
    source "#{node['chef_oracle']['ora_repo_url']}/#{file['name']}"
    # checksum file['cksum']
    owner node['chef_oracle']['user']
    group node['chef_oracle']['group']
    mode '660'
  end

  execute 'unzip intall file' do
    command <<-EOH
      #wget #{node['chef_oracle']['ora_repo_url']}/#{file['name']}
      unzip #{file['name']} -d #{node['chef_oracle']['ora_inst_dir']}
      chown -R #{node['chef_oracle']['user']}:#{node['chef_oracle']['group']} #{node['chef_oracle']['ora_inst_dir']}/*
      rm -f #{file['name']}
    EOH
  end
end

# Install cvuqdisk for Oracle GI
execute 'install cvuqdisk rpm' do
  command "rpm -i #{node['chef_oracle']['ora_inst_dir']}/grid/rpm/cvuqdisk*"
  #only_if { node['platform'] == 'rhel' }
end
