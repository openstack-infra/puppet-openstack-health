# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health::frontend(
  $application_dir = under,
) {

  $service_config_file = "${application_dir}/openstack-health-frontend.conf"

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

  exec { 'install-gulp' :
    command => 'npm install -g gulp',
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    unless  => 'npm -g list | grep gulp',
    require => [
      Package['nodejs'],
      Package['npm'],
    ],
  }

  exec { 'install-openstack-health-frontend-requirements' :
    creates => "${application_dir}/node_modules",
    cwd     => $application_dir,
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    command => 'npm install',
    # Increasing the timeout due to the amount of dependencies
    # that will be downloaded.
    timeout => 600,
    require => [
      Package['npm'],
      Package['nodejs'],
      File['/usr/bin/node'],
    ]
  }

  file { $service_config_file:
    ensure  => present,
    mode    => '0644',
    content => template('openstack_health/openstack-health-frontend.conf.erb'),
  }

  file { '/etc/init/openstack-health-frontend.conf':
    ensure  => link,
    target  => $service_config_file,
    require => File[$service_config_file],
  }

  exec { 'reload-service-configuration-for-openstack-health-frontend':
    command => 'initctl reload-configuration',
    unless  => 'service openstack-health-frontend status',
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/', '/sbin'],
    require => File['/etc/init/openstack-health-frontend.conf'],
  }

  service { 'openstack-health-frontend' :
    ensure  => running,
    name    => 'openstack-health-frontend',
    enable  => true,
    require => [
      Exec['install-gulp'],
      Exec['install-openstack-health-frontend-requirements'],
      Exec['reload-service-configuration-for-openstack-health-frontend'],
    ],
  }
}
