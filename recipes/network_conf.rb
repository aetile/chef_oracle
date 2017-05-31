# -*- mode: ruby; coding: utf-8; -*-

# Repository hostname resolution
# hostsfile_entry node['chef_oracle']['repo_ip'] do
#   hostname  node['chef_oracle']['repo_host']
#   unique    true
# end

# Network default configuration
execute 'net nozeroconf' do
  command <<-EOH
    NOZEROCONF=`grep NOZEROCONF /etc/sysconfig/network | cut -d '=' -f 2`
    if [ -z $NOZEROCONF ]; then
      echo "NOZEROCONF=YES" >> /etc/sysconfig/network
    elif [ "$NOZEROCONF" != "YES" ]; then
      sed -i "s#NOZEROCONF\=$NOZEROCONF#NOZEROCONF\=YES#g" /etc/sysconfig/network
    fi
  EOH
end

if node['chef_oracle']['db']['cluster']
  include_recipe 'chef_oracle::dns_conf'
end
