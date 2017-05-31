# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_chef_oracle
# Recipe:: configure oracle environment
#

fail 'ASM must be enabled to install Oracle Grid Infrastruture.' unless node['chef_oracle']['asm']['enabled']

# Get install databag items
bag_item = node['chef_oracle']['db']['std']['databag']
db_bag = data_bag_item("db", bag_item)
fail 'Unable to load the db:#{bag_item} databag.' unless db_bag

grid_params = db_bag['install']['grid']
grid_inst = "#{node['chef_oracle']['ora_inst_dir']}/grid"
grid_rsp = "#{grid_inst}/grid.rsp"
grid_home = node['chef_oracle']['db']['grid_dir']

# Create response files
template grid_rsp do
  source 'grid.rsp'
  owner node['chef_oracle']['user']
  group node['chef_oracle']['group']
  mode '0644'
  variables(
    option: grid_params['option'],
    lang: grid_params['lang'],
    gns: grid_params['gns'],
    cluster_nodes: nil,
    host_name: node['hostname'],
    inv_path: node['chef_oracle']['ora_inv_dir'],
    oracle_base: node['chef_oracle']['ora_base_dir'],
    grid_home: node['chef_oracle']['db']['grid_dir'],
    dba_group:  node['chef_oracle']['dba'],
    osoper_group: node['chef_oracle']['group'],
    oinstall_group: node['chef_oracle']['group'],
    asm_sys_passwd: grid_params['asm_sys_passwd'],
    asm_snmp_passwd: grid_params['asm_snmp_passwd'],
    asm_diskgrp: grid_params['asm_data_dg'],
    asm_redundancy: grid_params['asm_redundancy'],
    asm_ausize: grid_params['asm_ausize'],
    asm_data: grid_params['asm_data_disks'],
    asm_redo: grid_params['asm_redo'],
    asm_discovery_str: grid_params['asm_discovery_str'],
    skip_updates: grid_params['skip_updates']
  )
  action [:delete, :create]
end

# GI silent install
execute 'install grid inf' do
  command <<-EOH
    su #{node['chef_oracle']['user']} -c "#{grid_inst}/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -showProgress -waitforcompletion -responseFile #{grid_inst}/grid.rsp"
  EOH
  not_if { Dir.exist?("#{grid_home}") }
end

execute 'update inventory' do
  command "#{node['chef_oracle']['ora_inv_dir']}/orainstRoot.sh"
  only_if { File.exist?("#{node['chef_oracle']['ora_inv_dir']}/orainstRoot.sh") }
end

# Create OCM response file
template '/home/oracle/ocm.rsp' do
  source 'ocm.rsp'
  owner node['chef_oracle']['user']
  group node['chef_oracle']['group']
  action :create
end

# Install latest Opatch utility
remote_file db_bag['opatch']['latest'] do
  source "#{node['chef_oracle']['ora_repo_url']}/opatch/#{db_bag['opatch']['latest']}"
  owner node['chef_oracle']['user']
  group node['chef_oracle']['group']
  mode '0660'
end

execute 'install opatch' do
  command <<-EOH
    #wget #{node['chef_oracle']['ora_repo_url']}/opatch/#{db_bag['opatch']['latest']}
    mv #{grid_home}/OPatch #{grid_home}/OPatch.old
    unzip #{db_bag['opatch']['latest']} -d #{grid_home}
    chown -R #{node['chef_oracle']['user']}:#{node['chef_oracle']['group']} #{grid_home}/OPatch
    rm -f #{db_bag['opatch']['latest']}
  EOH
end

# Install GI pre config patches
grid_params['opatch'].each do |opatch|
  remote_file opatch['file'] do
    source "#{node['chef_oracle']['ora_repo_url']}/opatch/#{opatch['file']}"
    owner node['chef_oracle']['user']
    group node['chef_oracle']['group']
    mode '0660'
    only_if { opatch['apply'] == 'pre' }
  end

  execute "install patch #{opatch['id']}" do
    command <<-EOH
      #wget #{node['chef_oracle']['ora_repo_url']}/p18286381_112040_Linux-x86-64.zip
      unzip -u #{opatch['file']} -d #{grid_home}/OPatch
      chown -R #{node['chef_oracle']['user']}:#{node['chef_oracle']['group']} #{grid_home}/OPatch
      rm -f #{opatch['file']}
      export ORACLE_HOME=#{grid_home}
      export LD_LIBRARY_PATH=#{grid_home}/lib:#{grid_home}/OPatch/#{opatch['id']}/oui/lib:/lib:/usr/lib
      export OPATCH_PLATFORM_ID=#{db_bag['opatch']['platform_id']}
      export PATH=$PATH:#{grid_home}/OPatch
      cd #{grid_home}/OPatch/#{opatch['id']}
      su oracle -c "#{grid_home}/OPatch/opatch apply -silent -ocmrf /home/oracle/ocm.rsp"
    EOH
    only_if { opatch['apply'] == 'pre' }
  end
end

# Create ohasd service for systemd if RHEL7
template '/etc/systemd/system/ohasd.service' do
  source 'ohasd.service.erb'
  owner node['chef_oracle']['superuser']
  group node['chef_oracle']['superuser']
  mode '0644'
  only_if { Dir.exist?('/etc/systemd') }
end

execute 'start ohasd' do
  command <<-EOH
    systemctl stop firewalld
    systemctl daemon-reload
    systemctl enable ohasd.service
    systemctl stop ohasd.service
    #systemctl start ohasd.service
    #systemctl status ohasd.service
  EOH
  only_if { Dir.exist?('/etc/systemd') }
end

# Configure GI
execute 'exec root script' do
  command "#{grid_home}/root.sh"
end

# Install GI post config patches
grid_params['opatch'].each do |opatch|
  remote_file opatch['file'] do
    source "#{node['chef_oracle']['ora_repo_url']}/opatch/#{opatch['file']}"
    owner node['chef_oracle']['user']
    group node['chef_oracle']['group']
    mode '0660'
    only_if { opatch['apply'] == 'post' }
  end

  execute "install patch #{opatch['id']}" do
    command <<-EOH
      unzip -u #{opatch['file']} -d #{grid_home}/OPatch
      rm -f #{opatch['file']}
      export ORACLE_HOME=#{grid_home}
      export OPATCH_PLATFORM_ID=#{db_bag['opatch']['platform_id']}
      export PATH=$PATH:#{grid_home}/OPatch
      cd #{grid_home}/OPatch/#{opatch['id']}
      su oracle -c "#{grid_home}/OPatch/opatch apply -silent -ocmrf /home/oracle/ocm.rsp"
    EOH
    only_if { opatch['apply'] == 'post' }
  end
end

# ASM silent install
execute 'asm install' do
  command <<-EOH
    su #{node['chef_oracle']['user']} -c "#{grid_home}/bin/asmca -silent -configureASM -sysAsmPassword '#{grid_params['asm_sys_passwd']}' -asmsnmpPassword '#{grid_params['asm_snmp_passwd']}' -diskString '#{grid_params['asm_discovery_str']}' -diskGroupName '#{grid_params['asm_data_dg']}' -disk '#{grid_params['asm_data_disks']}' -redundancy '#{grid_params['asm_redundancy']}'"
    su #{node['chef_oracle']['user']} -c "#{grid_home}/bin/asmca -silent -createDiskGroup -diskGroupName '#{grid_params['asm_redo_dg']}' -diskList '#{grid_params['asm_redo_disks']}' -redundancy '#{grid_params['asm_redundancy']}' -sysAsmPassword '#{grid_params['asm_sys_passwd']}' -asmsnmpPassword '#{grid_params['asm_snmp_passwd']}'"
  EOH
end
