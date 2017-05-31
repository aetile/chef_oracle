name 'chef_oracle'
maintainer 'Chef Software inc.'
license 'Apache 2.0'
description 'Installs/Configures oracle database'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.8'

depends 'limits', '~> 1.0.0'
depends 'sysctl', '~> 0.7.5'
depends 'lvm', '~> 4.1.0'
#depends 'lvm', '~> 1.3.7'
depends 'selinux', '~> 0.9.0'
depends 'yum', '~> 3.5.2'
depends 'yum-epel', '~> 0.6.5'
depends 'resolver', '~> 2.0.1'
#depends 'ntp', '~> 1.7.0'
#depends 'sudo', '~> 2.7.1'
#depends 'hostsfile', '~> 2.4.5'

supports 'redhat'
supports 'centos'

