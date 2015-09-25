# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health::frontend(
  $application_dir = under,
) {

  $frontend_service_config_file = "${application_dir}/openstack-health-frontend.conf"

  package { 'nodejs':
    ensure => present
  }

  package { 'npm':
    ensure => present
  }

  file { '/usr/bin/node':
    ensure  => link,
    target  => '/usr/bin/nodejs',
    require => Package['nodejs'],
  }

  exec { 'install-gulp':
    command => 'npm install -g gulp',
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    unless  => 'npm -g list | grep gulp',
    require => [
      Package['nodejs'],
      Package['npm'],
    ],
  }

  exec { 'install-openstack-health-frontend-requirements':
    command     => 'npm install',
    refreshonly => true,
    cwd         => $application_dir,
    path        => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    # Increasing the timeout due to the amount of dependencies
    # that will be downloaded.
    timeout     => 600,
    require     => [
      Package['npm'],
      Package['nodejs'],
      Exec['install-gulp'],
      File['/usr/bin/node'],
    ],
    subscribe   => Vcsrepo[$application_dir],
    notify      => Service['openstack-health-frontend'],
  }

  file { $frontend_service_config_file:
    ensure  => present,
    mode    => '0644',
    content => template('openstack_health/openstack-health-frontend.conf.erb'),
    notify  => Service['openstack-health-frontend'],
  }

  file { '/etc/init/openstack-health-frontend.conf':
    ensure  => link,
    mode    => '0644',
    target  => $frontend_service_config_file,
    require => File[$frontend_service_config_file],
  }

  exec { 'reload-service-configuration-for-openstack-health-frontend':
    command => 'initctl reload-configuration',
    unless  => 'service openstack-health-frontend status',
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/', '/sbin'],
    require => File['/etc/init/openstack-health-frontend.conf'],
  }

  service { 'openstack-health-frontend' :
    ensure    => running,
    name      => 'openstack-health-frontend',
    enable    => true,
    require   => File['/etc/init/openstack-health-frontend.conf'],
    subscribe => Vcsrepo[$application_dir],
  }
}
