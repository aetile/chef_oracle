# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_chef_oracle
# Recipe:: install_rpm_deps
#

# Install RPM prerquisites
rpm_list_add = node.default['chef_oracle']['deps']['add']
rpm_list_x86 = node.default['chef_oracle']['deps']['x86_64']
rpm_list_i686 = node.default['chef_oracle']['deps']['i686']
rpm_list_asm = node.default['chef_oracle']['deps']['asm']
rpm_list_rac = node.default['chef_oracle']['deps']['rac']

# Install required 64 bit RPMs
unless rpm_list_x86.nil?
  rpm_list_x86.each do |dep_x86|
    yum_package dep_x86 do
      arch 'x86_64'
      ignore_failure true
      action :install
    end
  end
end

# Install required 32 bits RPMs
unless rpm_list_i686.nil?
  rpm_list_i686.each do |dep_i686|
    yum_package dep_i686 do
      arch 'i686'
      ignore_failure true
      action :install
    end
  end
end

# Install additional dependencies
unless rpm_list_add.nil?
  rpm_list_add.each do |dep_add|
    yum_package dep_add do
      ignore_failure true
      action :install
    end
  end
end

# Install ASMLib RPMs
unless rpm_list_asm.nil?
  rpm_list_asm.each do |dep_asm|
    yum_package dep_asm do
      ignore_failure true
      action :install
      only_if { node['chef_oracle']['asm']['asmlib'] }
    end
  end
end

# Install RAC RPMs
unless rpm_list_rac.nil?
  if node['platform'] == 'redhat'
    rpm_list_rac.each do |dep_rac|
      yum_package dep_rac do
        ignore_failure true
        action :install
        only_if { node.role?('oracle_rac') }
      end
    end

    # Uninstall avahi
    yum_package 'avahi-daemon' do
      ignore_failure true
      action :remove
      only_if { node.role?('oracle_rac') }
    end
  end
end

# Enable autostart of storage services
service 'iscsi' do
  action [:enable, :start]
end

service 'iscsid' do
  action [:enable, :start]
end

service 'multipathd' do
  action [:enable, :start]
end
