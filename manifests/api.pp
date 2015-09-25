# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health::api(
  $application_dir = undef,
) {

  $virtualenv_dir = "${application_dir}/.venv/"
  $virtualenv_bin_path = "${virtualenv_dir}/bin"
  $virtualenv_lib_path = "${virtualenv_dir}/lib"
  $api_service_config_file = "${application_dir}/openstack-health-api.conf"

  class { '::python':
    version    => 'system',
    pip        => true,
    dev        => true,
    virtualenv => true,
  }

  ::python::virtualenv { $virtualenv_dir:
    ensure => present
  }

  exec { 'install-openstack-health-api-requirements':
    command     => "${virtualenv_bin_path}/pip install -r requirements.txt",
    refreshonly => true,
    cwd         => $application_dir,
    path        => ['/usr/local/bin/', '/usr/bin/', '/bin/', '/sbin/'],
    require     => Python::Virtualenv[$virtualenv_dir],
    subscribe   => Vcsrepo[$application_dir],
    notify      => Service['openstack-health-api'],
  }

  file { $api_service_config_file:
    ensure  => present,
    mode    => '0644',
    content => template('openstack_health/openstack-health-api.conf.erb'),
    notify  => Service['openstack-health-api'],
  }

  file { '/etc/init/openstack-health-api.conf':
    ensure  => link,
    mode    => '0644',
    target  => $api_service_config_file,
    require => File[$api_service_config_file],
  }

  exec { 'reload-service-configuration-for-openstack-health-api':
    command => 'initctl reload-configuration',
    unless  => 'service openstack-health-api status',
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/', '/sbin'],
    require => File['/etc/init/openstack-health-api.conf'],
  }

  service { 'openstack-health-api':
    ensure    => running,
    name      => 'openstack-health-api',
    enable    => true,
    require   => File['/etc/init/openstack-health-api.conf'],
    subscribe => Vcsrepo[$application_dir],
  }
}
