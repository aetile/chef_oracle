# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_oracle
# Recipe:: configure_os
#

# Compute customized kernel memory config
bag_item = node['chef_oracle']['db']['std']['databag']
db_bag = data_bag_item('db', bag_item)

if db_bag['kernel']['hugepages'] > 0
  node.default['sysctl']['params']['vm']['nr_hugepages'] = db_bag['kernel']['hugepages']
else
  node.default['sysctl']['params']['vm']['nr_hugepages'] = node['sysctl']['hugepages_pct'].to_i * node['memory']['total'].split('kB')[0].to_i / 100 / 1_024 / 2
end

# Check if memory parameters are valid
sys_mem = node['memory']['total'].split('kB')[0].to_i - (node['sysctl']['params']['vm']['nr_hugepages'].to_i * 2 * 1_024)
fail 'Too much hugepages configured for the system.' unless sys_mem >= (512 * 1_024)

kern_pagesize = shell_out('getconf PAGESIZE')
node.default['sysctl']['params']['kernel']['shmmax'] = 1_024 * node['memory']['total'].split('kB')[0].to_i / 2
node.default['sysctl']['params']['kernel']['shmall'] = 1_024 * node['memory']['total'].split('kB')[0].to_i / kern_pagesize.stdout.to_i

include_recipe 'sysctl::apply'

# Kernel must not use transparent hugepages in memory
execute 'no trans hugepages' do
  command "sed -i 's#quiet#quiet\ transparent_hugepage\=never#g' #{db_bag['grub']['config_file']}"
  not_if "grep 'transparent_hugepage=never' #{db_bag['grub']['config_file']}"
end

# SELinux must be disabled
include_recipe 'selinux::disabled'
execute 'disable at boot' do
  command "sed -i 's#transparent_hugepage\=never#transparent_hugepage\=never\ selinux=0#g' #{db_bag['grub']['config_file']}"
  not_if "grep 'selinux=0' #{db_bag['grub']['config_file']}"
end
