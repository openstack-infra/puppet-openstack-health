# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health::frontend(
  $application_dir = under,
) {

  package { 'nodejs':
    ensure => present
  }

  package { 'npm':
    ensure => present
  }

  exec { 'create-node-symlink':
    creates => '/usr/bin/node',
    command => 'ln -s /usr/bin/nodejs /usr/bin/node',
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
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
      Exec['create-node-symlink'],
    ]
  }

  file { '/etc/init/openstack-health-frontend.conf' :
    ensure  => present,
    mode    => '0644',
    content => template('openstack_health/openstack-health-frontend.conf.erb'),
    require => Exec['install-openstack-health-frontend-requirements'],
  }

  service { 'openstack-health-frontend' :
    ensure  => running,
    name    => 'openstack-health-frontend',
    enable  => true,
    require => [
      Exec['install-gulp'],
      File['/etc/init/openstack-health-frontend.conf'],
    ],
  }
}
