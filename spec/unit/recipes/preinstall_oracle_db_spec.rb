# -*- mode: ruby; coding: utf-8; -*-
#
# Cookbook Name:: preinstall_oracle_db
# Spec:: default
#

require 'spec_helper'

ora_groups = ['dba']
rpm_deps_x86 = ['binutils', 'gcc', 'gcc-c++', 'glibc', 'glibc-devel', 'libgcc', 'libstdc++', 'libstdc++-devel', 'libaio', 'libaio-devel',
                'compat-libcap1', 'compat-libstdc++', 'ksh', 'make', 'sysstat', 'xorg-x11-apps', 'xorg-x11-xauth', 'xorg-x11-utils',
                'keyutils', 'elfutils-libelf', 'elfutils-libelf-devel', 'oracleasmlib', 'oracleasm-support']
rpm_deps_i686 = ['glibc', 'glibc-devel', 'libgcc', 'libstdc++', 'libstdc++-devel', 'libaio', 'libaio-devel', 'compat-libstdc++']
rpm_deps_add = ['device-mapper-multipath', 'iscsi-initiator-utils', 'kmod-oracleasm', 'unixODBC', 'cifs-utils', 'nfs-utils', 'nc']

describe 'chef_oracle::configure_kernel' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '6.8',
      role_path: '/home/arnaw/chef_oracle/test/integration/roles'
    ) do |node|
      node.automatic['memory']['total'] = '2048000kB'
    end.converge('role[oracle_db]', 'chef_oracle::configure_kernel')
  end

  kernel_shmmax = 1_048_576_000
  kernel_shmall = 512_000
  kernel_hugepages = 450

  it 'should create custom limits config file' do
    expect(chef_run).to create_file('/etc/security/limits.d/oracle_limits.conf').with(
      owner: 'root',
      group: 'root',
      mode: '0644'
    )
  end

  it 'should customize limits parameters for Oracle user' do
    expect(chef_run).to render_file('/etc/security/limits.d/oracle_limits.conf').with_content(match('oracle soft memlock unlimited'))
    expect(chef_run).to render_file('/etc/security/limits.d/oracle_limits.conf').with_content(match('oracle hard memlock unlimited'))
    expect(chef_run).to render_file('/etc/security/limits.d/oracle_limits.conf').with_content(match('oracle soft nofile  65536'))
    expect(chef_run).to render_file('/etc/security/limits.d/oracle_limits.conf').with_content(match('oracle hard nofile  65536'))
    expect(chef_run).to render_file('/etc/security/limits.d/oracle_limits.conf').with_content(match('oracle soft nproc   16384'))
    expect(chef_run).to render_file('/etc/security/limits.d/oracle_limits.conf').with_content(match('oracle hard nproc   1638'))
  end

  it 'should create custom kernel parameter file from template' do
    expect(chef_run).to create_file('/etc/sysctl.d/99-chef-attributes.conf').with(
      owner: 'root',
      group: 'root',
      mode: '0644'
    )
  end

  it 'should customize kernel parameters for Oracle installation' do
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match('kernel.shmmni=4096'))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match('kernel.sem=250   32000   100      128'))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match("kernel.shmall=#{kernel_shmall}"))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match("kernel.shmmax=#{kernel_shmmax}"))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match("vm.nr_hugepages=#{kernel_hugepages}"))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match('core.rmem_default=26144'))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match('core.wmem_default=26144'))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match('core.rmem_max=414304'))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match('core.wmem_max=1048576'))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match('fs.file-max=6815744'))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match('fs.aio-max-nr=1048576'))
    expect(chef_run).to render_file('/etc/sysctl.d/99-chef-attributes.conf').with_content(match('net.ipv4.ip_local_port_range=9000 65500'))
  end

  it 'should create ntpd config file from template' do
    expect(chef_run).to create_file('/etc/sysconfig/ntpd').with(
      owner: 'root',
      group: 'root',
      mode: '0644'
    )
  end

  it 'should run ntpd with -x option' do
    expect(chef_run).to render_file('/etc/sysconfig/ntpd').with_content(match('OPTIONS="-x -u ntp:ntp -p /var/run/ntpd.pid -g"'))
  end

  it 'should disable SELinux' do
    expect(chef_run).to render_file('/etc/sysconfig/selinux').with_content(match('SELINUX=disabled'))
  end
end

describe 'chef_oracle::configure_oracle_env' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '6.6'
    ) do ||
    end.converge(described_recipe)
  end

  it 'should create user group Oracle' do
    expect(chef_run).to create_group('oinstall').with(
      gid: 201
    )
  end

  it 'should create user Oracle' do
    expect(chef_run).to create_user('oracle').with(
      uid: 200,
      gid: 201,
      shell: '/bin/bash'
    )
  end

  ora_groups.each do |grp|
    it "should add Oracle user as member of #{grp} group" do
      expect(chef_run).to modify_group('dba').with(
        members: ['oracle']
      )
    end
  end

  it 'should create Oracle base directory' do
    expect(chef_run).to create_directory('/opt/app/oracle/11.2.0.4/base').with(
      owner: 'oracle',
      group: 'oinstall',
      mode: '0755'
    )
  end

  it 'should create Oracle DB home directory' do
    expect(chef_run).to create_directory('/opt/app/oracle/11.2.0.4/base/dbhome').with(
      owner: 'oracle',
      group: 'oinstall',
      mode: '0755'
    )
  end

  it 'should create Oracle GI home directory' do
    expect(chef_run).to create_directory('/opt/app/oracle/11.2.0.4/grid').with(
      owner: 'oracle',
      group: 'oinstall',
      mode: '0755'
    )
  end

  it 'should create Oracle install files directory' do
    expect(chef_run).to create_directory('/opt/app/oracle/oracle_install').with(
      owner: 'oracle',
      group: 'oinstall',
      mode: '0755'
    )
  end

  it 'should create Oracle inventory directory' do
    expect(chef_run).to create_directory('/home/oracle/oraInventory').with(
      owner: 'oracle',
      group: 'oinstall',
      mode: '0755'
    )
  end

  it 'should create Oracle user profile' do
    expect(chef_run).to create_template('/home/oracle/.bash_profile').with(
      owner: 'oracle',
      group: 'oinstall',
      mode: '0755'
    )
  end

  it 'should create default Oracle user profile' do
    expect(chef_run).to create_template('/etc/profile.d/oracle.sh').with(
      owner: 'root',
      group: 'root',
      mode: '0755'
    )
  end
end

describe 'chef_oracle::install_rpm_deps' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      platform: 'centos',
      version: '6.6'
    ) do ||
    end.converge(described_recipe)
  end

  rpm_deps_x86.each do |dep_x86|
    before do
      stub_command("yum info #{dep_x86}").and_return(false)
      it "should install #{dep_x86} RPM package for x86_64 architecture" do
        expect(chef_run).to install_rpm_package("#{dep_x86}")
      end
    end
  end

  rpm_deps_i686.each do |dep_i686|
    before do
      stub_command("yum info #{dep_i686}").and_return(false)
      it "should install #{dep_i686} RPM package for i686 architecture" do
        expect(chef_run).to install_rpm_package("#{dep_i686}")
      end
    end
  end

  rpm_deps_add.each do |dep|
    before do
      stub_command("yum info #{dep}").and_return(false)
      it "should install additional #{dep} required RPM package" do
        expect(chef_run).to install_rpm_package("#{dep}")
      end
    end
  end
end
