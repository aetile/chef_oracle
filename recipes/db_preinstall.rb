# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: preinstall_oracle_db
# Spec:: default
#

include_recipe 'chef_oracle::attrib'
include_recipe 'chef_oracle::network_conf'
include_recipe 'chef_oracle::yum_repo'
include_recipe 'chef_oracle::limits_conf'
include_recipe 'chef_oracle::kernel_conf'
include_recipe 'chef_oracle::services_conf'
include_recipe 'chef_oracle::lvm_conf'
include_recipe 'chef_oracle::rpm_deps'
include_recipe 'chef_oracle::ora_env'
include_recipe 'chef_oracle::asm_conf'
