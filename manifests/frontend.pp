# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health::frontend(
  $application_dir = under,
) {

  $frontend_service_config_file = "${application_dir}/openstack-health-frontend.conf"

  class { '::nodejs':
    manage_package_repo       => false,
    nodejs_dev_package_ensure => 'present',
    npm_package_ensure        => 'present',
  }

  package { 'gulp':
    ensure   => 'present',
    provider => 'npm',
    require  => Class['::nodejs'],
  }

  # There isn't a way of doing that with puppet-nodejs yet.
  # See: https://github.com/puppet-community/puppet-nodejs/issues/154
  exec { 'install-openstack-health-frontend-requirements':
    command     => 'npm install',
    cwd         => $application_dir,
    refreshonly => true,
    path        => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    # Increasing the timeout due to the amount of dependencies
    # that will be downloaded.
    timeout     => 600,
    require     => Package['gulp'],
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
    notify  => Service['openstack-health-frontend'],
  }

  service { 'openstack-health-frontend' :
    ensure    => running,
    name      => 'openstack-health-frontend',
    enable    => true,
    require   => File['/etc/init/openstack-health-frontend.conf'],
    subscribe => Vcsrepo[$application_dir],
  }
}
