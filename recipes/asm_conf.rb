# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_oracle
# Recipe:: configure_asm
#
#

bag_item = node['chef_oracle']['db']['std']['databag']
db_bag = data_bag_item("db", bag_item)
fail 'Unable to load the db:#{bag_item} databag.' unless db_bag

asm_disks = db_bag['asm']['disks']

# ASM configuration file
template '/etc/sysconfig/oracleasm' do
  source 'asm_conf.erb'
  owner node['chef_oracle']['superuser']
  group node['chef_oracle']['superuser']
  mode '0644'
  only_if { node['chef_oracle']['asm']['asmlib'] }
end

# Initialize ASMLib
execute 'init asmlib' do
  command 'oracleasm configure && oracleasm init'
  not_if 'service oracleasm status | grep "Checking if ASM is loaded: yes" && service oracleasm status | grep "Checking if /dev/oracleasm is mounted: yes"'
  only_if { node['chef_oracle']['asm']['asmlib'] }
end

# Rescan ASM disks
execute 'asm_rescan' do
  command 'oracleasm scandisks'
  action :nothing
  only_if { node['chef_oracle']['asm']['asmlib'] }
end

# Create ASM disks
asm_disks.each do |disk|
  execute 'create asm disks' do
    command "oracleasm createdisk #{disk['lvname']} /dev/#{disk['vgname']}/#{disk['lvname']}"
    not_if "oracleasm listdisks | grep -i #{disk['name']}"
    notifies :run, 'execute[asm_rescan]', :immediately
    only_if { node['chef_oracle']['asm']['asmlib'] }
  end
end

# Use udev rules instead of ASM
#db_bag['asm']['disks'].each do |disk|
#  asm_disks = [ disk['lvname'], disk['vgname'] ]
#end

#case node['platform_version']
#when /6./
#  udev_src = 'udev_asm_6.erb'
#when /7./
#  udev_src = 'udev_asm_7.erb'
#else
#  #nothing
#end

template '/etc/udev/rules.d/99-oracle-asmdevices.rules' do
  source 'udev_asm.erb'
  owner node['chef_oracle']['superuser']
  group node['chef_oracle']['superuser']
  mode '0644'
  variables(
   disks: db_bag['asm']['disks'],
   owner: node['chef_oracle']['user'],
   group: node['chef_oracle']['group'],
   mode: '0660'
  )
  not_if { node['chef_oracle']['asm']['asmlib'] }
end

execute 'restart udev' do
#  command '/sbin/start_udev'
  command <<-EOH
    #/sbin/udevadm control --reload-rules
    #/sbin/udevadm trigger --type=devices --action=change
    /sbin/udevadm trigger --type=subsystems --action=change
    /sbin/udevadm trigger --type=devices --action=add
    /sbin/udevadm control --reload-rules
  EOH
  not_if { node['chef_oracle']['asm']['asmlib'] }
end
