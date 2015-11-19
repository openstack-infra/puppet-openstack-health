# Install and maintain OpenStack Health.
# params:
#   source_dir:
#     The directory where the application will be running
#   serveradmin:
#     Used in the Apache virtual host, eg., openstack-health@openstack.org
#   vhost_name:
#     Used in the Apache virtual host, eg., health.openstack.org
#   vhost_port:
#     Used in the Apache virtual host, eg., 5000
class openstack_health::api(
  $db_uri = undef,
  $source_dir = '/opt/openstack-health',
  $server_admin = "webmaster@${::fqdn}",
  $vhost_name = 'localhost',
  $vhost_port = 5000,
  $ignored_run_metadata_keys = ['build_change',
                                'build_node',
                                'build_patchset',
                                'build_ref',
                                'build_short_uuid',
                                'build_uuid',
                                'build_zuul_url'],
) {

  include ::httpd::mod::wsgi

  $api_dir = "${source_dir}/openstack_health"
  $virtualenv_dir = "${source_dir}/.venv"

  class { '::python':
    dev        => true,
    pip        => true,
    virtualenv => true,
    version    => 'system',
  }

  ::python::virtualenv { $virtualenv_dir:
    ensure  => present,
    require => Class['::python'],
  }

  ::python::requirements { "${source_dir}/requirements.txt":
    virtualenv => $virtualenv_dir,
    require    => Python::Virtualenv[$virtualenv_dir],
    subscribe  => Vcsrepo[$source_dir],
  }

  exec { 'package-application':
    command     => "${virtualenv_dir}/bin/pip install -e ${source_dir}",
    require     => Python::Requirements["${source_dir}/requirements.txt"],
    refreshonly => true,
    subscribe   => Vcsrepo[$source_dir],
  }

  file { '/etc/openstack-health.conf':
    ensure    => present,
    content   => template('openstack_health/openstack-health.conf.erb'),
    owner     => 'openstack_health',
    group     => 'openstack_health',
    mode      => '0644',
    subscribe => Vcsrepo[$source_dir],
  }

  ::httpd::vhost { "${vhost_name}-api":
    docroot  => 'MEANINGLESS ARGUMENT',
    port     => $vhost_port,
    priority => '50',
    ssl      => false,
    template => 'openstack_health/openstack-health-api.vhost.erb',
    require  => [
      File['/etc/openstack-health.conf'],
      Exec['package-application'],
    ],
  }
  if ! defined(Httpd::Mod['cache']) {
    httpd::mod { 'cache':
      ensure => present,
    }
  }

  if $::operatingsystem == 'Ubuntu' and $::operatingsystemrelease == '12.04' {
    $cache_disk_module = 'disk_cache'
  } else {
    $cache_disk_module = 'cache_disk'
  }
  if ! defined(Httpd::Mod[$cache_disk_module]) {
    httpd::mod { $cache_disk_module:
      ensure => present,
    }
  }
}
