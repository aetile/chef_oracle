# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_chef_oracle
# Recipe:: configure oracle environment
#

# Get install databag items
begin
  db_bag = data_bag_item("db_params", "db")
rescue Net::HTTPServerException
  raise("Unable to load the db_params:db databag.")
end

db_params = db_bag['install']['dbms']
grid_params = db_bag['install']['grid']
grid_inst = "#{node['chef_oracle']['ora_inst_dir']}/grid"
grid_rsp = "#{grid_inst}/grid.rsp"
grid_home = node['chef_oracle']['db']['grid_dir']
db_inst = "#{node['chef_oracle']['ora_inst_dir']}/database"
db_rsp = "#{db_inst}/db.rsp"
db_home = node['chef_oracle']['db']['home_dir']

# GI silent uninstall
if ::Dir.exist?("#{grid_home}/bin")
  template '/tmp/GI_uninstall.rsp' do
    source 'grid_deinstall.erb'
    owner node['chef_oracle']['user']
    group node['chef_oracle']['group']
    mode '0644'
    variables(
      option: grid_params['option'],
      host_name: node['hostname'],
      cluster_nodes: nil,
      inv_path: node['chef_oracle']['ora_inv_dir'],
      oracle_base: node['chef_oracle']['ora_base_dir'],
      oracle_home: node['chef_oracle']['db']['home_dir'],
      dba_group:  node['chef_oracle']['dba'],
      osoper_group: node['chef_oracle']['group'],
      oinstall_group: node['chef_oracle']['group'],
      asm_discovery_str: grid_params['asm_discovery_str']
    )
    action [:delete, :create]
  end

  execute 'uninstall GI' do
    command <<-EOH
      su - oracle -c "#{grid_home}/deinstall/deinstall -checkonly"
      su - oracle -c "#{grid_home}/deinstall/deinstall -silent -paramfile /tmp/GI_uninstall.rsp"
      rm -rf #{node['chef_oracle']['ora_inv_dir']}
    EOH
  end
end

# DBMS silent uninstall
if ::Dir.exist?("#{db_home}/bin")
  template '/tmp/DBS_uninstall.rsp' do
    source 'dbs_deinstall.erb'
    owner node['chef_oracle']['user']
    group node['chef_oracle']['group']
    mode '0644'
    variables(
      option: db_params['option'],
      host_name: node['hostname'],
      cluster_nodes: node['hostname'],
      inv_path: node['chef_oracle']['ora_inv_dir'],
      oracle_base: node['chef_oracle']['ora_base_dir'],
      oracle_home: node['chef_oracle']['db']['home_dir'],
      dba_group:  node['chef_oracle']['dba'],
      osoper_group: node['chef_oracle']['group'],
      oinstall_group: node['chef_oracle']['group'],
      asm_discovery_str: grid_params['asm_discovery_str']
    )
    action [:delete, :create]
  end

  execute 'uninstall DBMS' do
    command <<-EOH
      su - oracle -c "#{db_home}/deinstall/deinstall -checkonly"
      su - oracle -c "#{db_home}/deinstall/deinstall -silent -paramfile /tmp/DBS_uninstall.rsp"
      rm -rf #{node['chef_oracle']['ora_inv_dir']}
    EOH
  end
end
