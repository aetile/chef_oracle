# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_chef_oracle
# Recipe:: configure oracle environment
#

# Get install databag items
bag_item = node['chef_oracle']['db']['std']['databag']
db_bag = data_bag_item("db", bag_item)
fail 'Unable to load the db:#{bag_item} databag.' unless db_bag

db_params = db_bag['install']

# Check if memory parameters are valid
huge_mem = (node['sysctl']['params']['vm']['nr_hugepages'].to_i * 2) - db_params['dbca']['memory_mb']
fail 'Memory allocated to Oracle instance exceeds configured hugepages.' unless huge_mem > 0

# Create response file
template "#{node['chef_oracle']['home']}/dbca.rsp" do
  source 'dbca.rsp'
  owner node['chef_oracle']['user']
  group node['chef_oracle']['group']
  mode '0644'
  variables(
    op_type: 'createDatabase',
    charset: db_params['dbca']['charset'],
    ncharset: db_params['dbca']['ncharset'],
    db_name: db_params['dbca']['db_name'],
    domain: db_params['dbca']['domain'],
    db_sid: db_params['dbca']['db_sid'],
    listeners: db_params['dbca']['listeners'],
    amm: db_params['dbca']['amm'],
    memory: db_params['dbca']['memory_mb'],
    db_type: db_params['dbca']['db_type'],
    spfile_loc: db_params['dbca']['spfile_loc'],
    init_params: db_params['dbca']['init_params'],
    db_template: db_params['dbca']['db_template'],
    sample_schemas: db_params['dbca']['sample_schemas'],
    sys_password: db_params['dbca']['sys_password'],
    system_password: db_params['dbca']['system_password'],
    storage_type: db_params['dbca']['storage_type'],
    asmsnmp_password: db_params['grid']['asm_snmp_passwd'],
    asm_data_dg: db_params['dbca']['asm_data_dg']
  )
  action [:delete, :create]
end

execute 'create db' do
  command <<-EOH
    su -l #{node['chef_oracle']['user']} -c "#{node['chef_oracle']['db']['home_dir']}/bin/dbca -silent -responseFile #{node['chef_oracle']['home']}/dbca.rsp"
  EOH
  not_if "grep #{db_params['dbca']['db_sid']} /etc/oratab"
end

template "#{node['chef_oracle']['db']['home_dir']}/dbs/init#{db_params['dbca']['db_sid']}.ora" do
  source 'init.ora'
  owner node['chef_oracle']['user']
  group node['chef_oracle']['group']
  mode '0644'
  variables(
    initparams: db_params['dbca']['initparams'],
    db_sid: db_params['dbca']['db_sid'],
    asm_data_dg: db_params['dbca']['asm_data_dg']
  )
  action [:delete, :create]
end

# Tell Oracle Restart to use pfile instead of spfile
execute 'restart db' do
  command <<-EOH
    su -l #{node['chef_oracle']['user']} -c "srvctl stop database -d #{db_params['dbca']['db_sid']}"
    su -l #{node['chef_oracle']['user']} -c "srvctl modify database -d #{db_params['dbca']['db_sid']} -p ''"
    su -l #{node['chef_oracle']['user']} -c "srvctl start database -d #{db_params['dbca']['db_sid']}"
  EOH
end
