# == Class: gerrit::user
#
class openstack_health::user {
  group { 'openstack_health':
    ensure => present,
  }

  user { 'openstack_health':
    ensure     => present,
    comment    => 'Openstack-Health User',
    home       => '/home/openstack_health',
    gid        => 'openstack_health',
    shell      => '/bin/bash',
    membership => 'minimum',
    require    => ::Group['openstack_health'],
  }

  file { '/home/openstack_health':
    ensure  => directory,
    owner   => 'openstack_health',
    group   => 'openstack_health',
    mode    => '0644',
    require => ::User['openstack_health'],
  }
}
