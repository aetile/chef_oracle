# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: preinstall_oracle_db
# Spec:: default
#

require 'json'
require 'spec_helper'
rpm_deps_x86 = ['binutils', 'gcc', 'gcc-c++', 'glibc', 'glibc-devel', 'libgcc', 'libstdc++',
                'libstdc++-devel', 'libaio', 'libaio-devel', 'compat-libcap1',
                'compat-libstdc++-33', 'ksh', 'make', 'sysstat', 'xorg-x11-apps',
                'xorg-x11-xauth', 'xorg-x11-utils', 'keyutils', 'elfutils-libelf',
                'elfutils-libelf-devel', 'ntp', 'ntpdate']
rpm_deps_i686 = ['glibc', 'glibc-devel', 'libgcc', 'libstdc++', 'libstdc++-devel', 'libaio',
                 'libaio-devel', 'compat-libstdc++-33']
rpm_deps_add = ['device-mapper-multipath', 'iscsi-initiator-utils', 'oracleasm-support',
                'oracleasmlib', 'kmod-oracleasm', 'unixODBC', 'cifs-utils', 'nfs-utils', 'nc', 'ntp', 'ntpdate']
# rpm_deps_x86 = ['binutils', 'gcc', 'gcc-c++', 'glibc', 'glibc-devel', 'libgcc', 'libstdc++', 'libstdc++-devel', 'libaio', 'libaio-devel',
#                 'compat-libcap1', 'compat-libstdc++', 'ksh', 'make', 'sysstat', 'xorg-x11-apps', 'xorg-x11-xauth', 'xorg-x11-utils',
#                 'keyutils', 'elfutils-libelf', 'elfutils-libelf-devel', 'oracleasmlib', 'oracleasm-support']
# rpm_deps_i686 = ['glibc', 'glibc-devel', 'libgcc', 'libstdc++', 'libstdc++-devel', 'libaio', 'libaio-devel', 'compat-libstdc++']
# rpm_deps_add = ['device-mapper-multipath', 'iscsi-initiator-utils', 'kmod-oracleasm', 'unixODBC', 'cifs-utils', 'nfs-utils', 'nc']
limits_cnf = '/etc/security/limits.d/oracle_limits.conf'
kernel_cnf = '/etc/sysctl.d/99-chef-attributes.conf'
ntp_cnf = '/etc/sysconfig/ntpd'
selinux_cnf = '/etc/sysconfig/selinux'
grub_cnf = '/boot/grub/grub.conf'
db_role_path = '/home/arnaw/chef_oracle/test/integration/roles/oracle_db.json'

describe user('oracle') do
  it { should exist }
  it { should belong_to_group 'oinstall' }
  it { should belong_to_group 'dba' }
end

describe file(limits_cnf) do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }

  its(:content) { should match /oracle soft memlock unlimited/ }
  its(:content) { should match /oracle hard memlock unlimited/ }
  its(:content) { should match /oracle soft nofile  65536/ }
  its(:content) { should match /oracle hard nofile  65536/ }
  its(:content) { should match /oracle soft nproc   16384/ }
  its(:content) { should match /oracle hard nproc   16384/ }
end

describe file(kernel_cnf) do
  let(:node) { JSON.parse(IO.read(db_role_path)) }
  kernel_shmmax = 1024 * host_inventory['memory']['total'].split('kB')[0].to_i / 2
  kernel_shmall = 1024 * host_inventory['memory']['total'].split('kB')[0].to_i / 4_096
  kernel_hugepages = 45 * host_inventory['memory']['total'].split('kB')[0].to_i / 100 / 1_024 / 2

  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }

  its(:content) { should match /kernel.shmmni=4096/ }
  its(:content) { should match /kernel.semmsl=250/ }
  its(:content) { should match /kernel.semmns=32000/ }
  its(:content) { should match /kernel.semopm=100/ }
  its(:content) { should match /kernel.semmni=128/ }
  its(:content) { should match /kernel.sem=250   32000   100      128/ }
  its(:content) { should match /kernel.shmall=#{kernel_shmall}/ }
  its(:content) { should match /kernel.shmmax=#{kernel_shmmax}/ }
  its(:content) { should match /vm.nr_hugepages=#{kernel_hugepages}/ }
  its(:content) { should match /net.core.rmem_default=262144/ }
  its(:content) { should match /net.core.wmem_default=262144/ }
  its(:content) { should match /net.core.rmem_max=4194304/ }
  its(:content) { should match /net.core.wmem_max=1048576/ }
  its(:content) { should match /fs.file-max=6815744/ }
  its(:content) { should match /fs.aio-max-nr=1048576/ }
  its(:content) { should match /net.ipv4.ip_local_port_range=9000 65500/ }
end

describe file(ntp_cnf) do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }

  its(:content) { should match %q(OPTIONS="-x -u ntp:ntp -p /var/run/ntpd.pid -g") }
end

describe file(selinux_cnf) do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }

  its(:content) { should match /SELINUX=disabled/ }
end

describe file(grub_cnf) do
  it { should be_file }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }

  its(:content) { should match /transparent_hugepage=never/ }
end

rpm_deps_x86.each do |dep_x86|
  describe package(dep_x86), :if => os[:family] == 'redhat' do
    it { should be_installed }
  end
end

rpm_deps_i686.each do |dep_i686|
  describe package(dep_i686), :if => os[:family] == 'redhat' do
    it { should be_installed }
  end
end

rpm_deps_add.each do |dep|
  describe package(dep), :if => os[:family] == 'redhat' do
    it { should be_installed }
  end
end

describe service('iscsi'), :if => os[:family] == 'redhat' do
  it { should be_enabled }
end

describe service('iscsid'), :if => os[:family] == 'redhat' do
  it { should be_enabled }
end

describe service('multipathd'), :if => os[:family] == 'redhat' do
  it { should be_enabled }
  it { should be_running }
end

describe service('oracleasm'), :if => os[:family] == 'redhat' do
  it { should be_enabled }
  it { should be_running }
end
