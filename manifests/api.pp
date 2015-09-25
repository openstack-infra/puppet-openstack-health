# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health::api(
  $application_dir = undef,
) {

  $virtualenv_bin_path = "${application_dir}/.venv/bin"
  $virtualenv_lib_path = "${application_dir}/.venv/lib"

  package { 'python-dev':
    ensure => present,
  }

  package { 'virtualenv':
    ensure   => present,
    provider => pip,
  }

  exec { 'create-openstack-health-virtualenv' :
    creates   => "${application_dir}/.venv",
    command   => "virtualenv ${application_dir}/.venv",
    subscribe => Vcsrepo[$application_dir],
    path      => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    require   => [
      Package['python-dev'],
      Package['virtualenv'],
    ]
  }

  exec { 'install-openstack-health-api-requirements' :
    command => "${virtualenv_bin_path}/pip install -r requirements.txt",
    creates => "${virtualenv_lib_path}/python2.7/site-packages/flask",
    cwd     => $application_dir,
    path    => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    require => Exec['create-openstack-health-virtualenv'],
  }

  file { '/etc/init/openstack-health-api.conf':
    ensure  => present,
    mode    => '0644',
    content => template('openstack_health/openstack-health-api.conf.erb'),
    require => Exec['install-openstack-health-api-requirements'],
  }

  service { 'openstack-health-api':
    ensure  => running,
    name    => 'openstack-health-api',
    require => File['/etc/init/openstack-health-api.conf'],
    enable  => true,
  }
}
