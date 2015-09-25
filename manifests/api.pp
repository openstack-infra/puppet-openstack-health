# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health::api(
  $application_dir = undef,
) {

  $virtualenv_bin_path = "${application_dir}/.venv/bin"
  $virtualenv_lib_path = "${application_dir}/.venv/lib"
  $service_config_file = "${application_dir}/openstack-health-api.conf"

  class { '::python':
    version    => 'system',
    pip        => true,
    dev        => true,
    virtualenv => true,
  }

  ::python::virtualenv { "${application_dir}/.venv":
    ensure => present
  }

  exec { 'install-openstack-health-api-requirements' :
    command => "${virtualenv_bin_path}/pip install -r requirements.txt",
    creates => "${virtualenv_lib_path}/python2.7/site-packages/flask",
    cwd     => $application_dir,
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    require => Python::Virtualenv["${application_dir}/.venv"]
  }

  file { $service_config_file:
    ensure  => present,
    mode    => '0644',
    content => template('openstack_health/openstack-health-api.conf.erb'),
  }

  file { '/etc/init/openstack-health-api.conf':
    ensure  => link,
    mode    => '0644',
    target  => $service_config_file,
    require => File[$service_config_file],
  }

  exec { 'reload-service-configuration-for-openstack-health-api':
    command => 'initctl reload-configuration',
    unless  => 'service openstack-health-api status',
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/', '/sbin'],
    require => File['/etc/init/openstack-health-api.conf'],
  }

  service { 'openstack-health-api':
    ensure  => running,
    name    => 'openstack-health-api',
    enable  => true,
    require => [
      Exec['install-openstack-health-api-requirements'],
      Exec['reload-service-configuration-for-openstack-health-api'],
    ],
  }
}
