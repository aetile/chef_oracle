# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: chef_chef_oracle
# Recipe:: configure oracle environment
#

# Get install databag items
bag_item = node['chef_oracle']['db']['std']['databag']
db_bag = data_bag_item("db", bag_item)
fail 'Unable to load the db:#{bag_item} databag.' unless db_bag

db_params = db_bag['install']['dbms']
db_inst = "#{node['chef_oracle']['ora_inst_dir']}/database"
db_rsp = "#{db_inst}/db.rsp"
db_home = node['chef_oracle']['db']['home_dir']

# Create response files
template db_rsp do
  source 'db.rsp'
  owner node['chef_oracle']['user']
  group node['chef_oracle']['group']
  mode '0644'
  variables(
    option: db_params['option'],
    edition: db_params['edition'],
    lang: db_params['lang'],
    host_name: node['hostname'],
    cluster_nodes: nil,
    inv_path: node['chef_oracle']['ora_inv_dir'],
    oracle_base: node['chef_oracle']['ora_base_dir'],
    oracle_home: node['chef_oracle']['db']['home_dir'],
    dba_group:  node['chef_oracle']['dba'],
    osoper_group: node['chef_oracle']['group'],
    oinstall_group: node['chef_oracle']['group'],
    use_oraclesupport: db_params['use_oraclesupport'],
    security_updates: db_params['security_updates'],
    proxy_host: db_params['proxy_host'],
    proxy_port: db_params['proxy_port'],
    proxy_user: db_params['proxy_user'],
    proxy_passwd: db_params['proxy_passwd'],
    proxy_realm: db_params['proxy_realm'],
    skip_updates: db_params['skip_updates']
  )
  action [:delete, :create]
end

# DBMS silent install
execute 'install dbms' do
  command <<-EOH
    su #{node['chef_oracle']['user']} -c "#{db_inst}/runInstaller -silent -ignoreSysPrereqs -ignorePrereq -showProgress -waitforcompletion -responseFile #{db_inst}/db.rsp"
  EOH
  not_if { Dir.exist?("#{db_home}") }
end

execute 'update inventory' do
  command "#{node['chef_oracle']['ora_inv_dir']}/orainstRoot.sh"
  only_if { File.exist?("#{node['chef_oracle']['ora_inv_dir']}/orainstRoot.sh") }
end

# Install DBMS pre config patches
db_params['opatch'].each do |opatch|
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
      unzip -u #{opatch['file']} -d #{db_home}/OPatch
      chown -R #{node['chef_oracle']['user']}:#{node['chef_oracle']['group']} #{db_home}/OPatch
      rm -f #{opatch['file']}
      export ORACLE_HOME=#{db_home}
      export OPATCH_PLATFORM_ID=#{db_bag['opatch']['platform_id']}
      export PATH=/usr/bin:$PATH:#{db_home}/OPatch
      cd #{db_home}/OPatch/#{opatch['id']}
      su oracle -c "#{db_home}/OPatch/opatch apply -silent -ocmrf /home/oracle/ocm.rsp"
    EOH
    only_if { opatch['apply'] == 'pre' }
  end
end

# Execute post install script
execute 'exec root script' do 
  command "#{db_home}/root.sh"
  # not_if "grep '#{db_home}' #{node['chef_oracle']['ora_inv_dir']}/ContentsXML/inventory.xml"
end

# Install DBMS post config patches
db_params['opatch'].each do |opatch|
  remote_file opatch['file'] do
    source "#{node['chef_oracle']['ora_repo_url']}/opatch/#{opatch['file']}"
    owner node['chef_oracle']['user']
    group node['chef_oracle']['group']
    mode '0660'
    only_if { opatch['apply'] == 'post' }
  end

  execute "install patch #{opatch['id']}" do
    command <<-EOH
      unzip -u #{opatch['file']} -d #{db_home}/OPatch
      chown -R #{node['chef_oracle']['user']}:#{node['chef_oracle']['group']} #{db_home}/OPatch
      rm -f #{opatch['file']}
      export ORACLE_HOME=#{db_home}
      export OPATCH_PLATFORM_ID=#{db_bag['opatch']['platform_id']}
      export PATH=/usr/bin:$PATH:#{db_home}/OPatch
      cd #{db_home}/OPatch/#{opatch['id']}
      su oracle -c "#{db_home}/OPatch/opatch apply -silent -ocmrf /home/oracle/ocm.rsp"
    EOH
    only_if { opatch['apply'] == 'post' }
  end
end
