# -*- mode: ruby; coding: utf-8; -*-
# Cookbook Name:: chef_oracle

# Get customized databag name
node.default['chef_oracle']['db']['std']['databag'] = "std_#{node.chef_environment.tr('-', '_').downcase}_#{node['platform']}#{node['platform_version']}"
node.default['chef_oracle']['db']['rac']['databag'] = "rac_#{node.chef_environment.tr('-', '_').downcase}_#{node['platform']}#{node['platform_version']}"

db_bag = data_bag_item('db', "#{node['chef_oracle']['db']['std']['databag']}")
fail 'Unable to load the db:std databag.' unless db_bag

rac_bag = data_bag_item('db', "#{node['chef_oracle']['db']['rac']['databag']}")
fail 'Unable to load the db:rac databag.' unless rac_bag

# Versions
node.default['chef_oracle']['db']['dbms'] = db_bag['dbms']
node.default['chef_oracle']['db']['version'] = db_bag['version']
node.default['chef_oracle']['db']['cluster'] = db_bag['cluster']
node.default['chef_oracle']['db']['sid'] = db_bag['install']['dbca']['db_sid']
node.default['chef_oracle']['db']['name'] = db_bag['dbname']
node.default['chef_oracle']['asm']['enabled'] = db_bag['asm']['enabled']
node.default['chef_oracle']['asm']['asmlib'] = db_bag['asm']['asmlib']

# Default Oracle user
node.default['chef_oracle']['superuser'] = db_bag['superuser']
node.default['chef_oracle']['user'] = db_bag['user']['name']
node.default['chef_oracle']['home'] = db_bag['user']['home']
node.default['chef_oracle']['uid'] = db_bag['user']['id']
node.default['chef_oracle']['group'] = db_bag['user']['group']
node.default['chef_oracle']['gid'] = db_bag['user']['gid']
node.default['chef_oracle']['dba'] = db_bag['dba']['name']
node.default['chef_oracle']['profile'] = "/home/#{db_bag['user']['name']}/.bash_profile"
node.default['chef_oracle']['root_profile'] = db_bag['root_profile']
node.default['chef_oracle']['shell'] = db_bag['user']['shell']
node.default['chef_oracle']['extra_groups'] = db_bag['user']['extra_groups']

# Default directory tree
node.default['chef_oracle']['app_dir'] = db_bag['app_dir']
node.default['chef_oracle']['ora_base_dir'] = "#{db_bag['app_dir']}/#{db_bag['user']['name']}/#{db_bag['version']}/base"
node.default['chef_oracle']['ora_inv_dir'] = "/home/#{db_bag['user']['name']}/oraInventory"
node.default['chef_oracle']['db']['home_dir'] = "#{db_bag['app_dir']}/#{db_bag['user']['name']}/#{db_bag['version']}/base/db"
node.default['chef_oracle']['db']['grid_dir'] = "#{db_bag['app_dir']}/#{db_bag['user']['name']}/#{db_bag['version']}/grid"
node.default['chef_oracle']['ora_inst_dir'] = "#{db_bag['app_dir']}/#{db_bag['user']['name']}/install"
node.default['chef_oracle']['rman_dir'] = db_bag['rman_dir']
node.default['chef_oracle']['ora_dir_tree'] = ["#{db_bag['app_dir']}/#{db_bag['user']['name']}",
                                               "#{db_bag['app_dir']}/#{db_bag['user']['name']}/install",
                                               "#{db_bag['app_dir']}/#{db_bag['user']['name']}/#{db_bag['version']}",
                                               "#{db_bag['app_dir']}/#{db_bag['user']['name']}/#{db_bag['version']}/base",
                                               "#{db_bag['app_dir']}/#{db_bag['user']['name']}/#{db_bag['version']}/base/admin",
                                               "#{db_bag['app_dir']}/#{db_bag['user']['name']}/#{db_bag['version']}/base/admin/scripts"]
# Default install files (YUM repositories)
node.default['chef_oracle']['rpm_repo_url'] = "#{db_bag['repo']['rpm_repo_url']}/#{node['platform_family']}-#{node['platform_version']}"
node.default['chef_oracle']['asm_repo_url'] = db_bag['repo']['asm_repo_url']
node.default['chef_oracle']['ora_repo_url'] = "#{db_bag['repo']['ora_repo_url']}/#{db_bag['version']}"
node.default['chef_oracle']['repo'] = db_bag['repo']

# RPM packages dependencies
os_distro = node['platform']
node.default['chef_oracle']['deps']['asm'] = db_bag['deps']['asm']
node.default['chef_oracle']['deps']['rac'] = db_bag['deps']['rac']
node.default['chef_oracle']['deps']['x86_64'] = db_bag['deps'][os_distro]['x86_64']
node.default['chef_oracle']['deps']['i686'] = db_bag['deps'][os_distro]['i686']
node.default['chef_oracle']['deps']['add'] = db_bag['deps'][os_distro]['adds']
node.default['chef_oracle']['db']['install_files'] = db_bag['install_files']
