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
  $ignored_run_metadata_keys = undef,
  $elastic_recheck_dir = '/opt/elastic-recheck',
  $elastic_recheck_repo = 'https://git.openstack.org/openstack-infra/elastic-recheck',
  $elastic_recheck_revision = 'master',
  $cache_expiration = 900,
) {

  include ::httpd::mod::wsgi

  $default_ignored_run_metadata_keys = ['build_change', 'build_node',
                                        'build_patchset', 'build_ref',
                                        'build_short_uuid', 'build_uuid',
                                        'build_zuul_url', 'filename',
                                        'build_newrev']

  if $ignored_run_metadata_keys {
    # In case it was defined, ensure the value provided is an array
    if is_array($ignored_run_metadata_keys) {
      $ignored_keys = $ignored_run_metadata_keys
    } else {
      fail('$ignored_run_metadata_keys parameter should be an array of strings')
    }
  } else {
    # In case it was not defined, use the default value
    $ignored_keys = $default_ignored_run_metadata_keys
  }

  $api_dir = "${source_dir}/openstack_health"

  class { '::python':
    dev        => true,
    pip        => true,
    virtualenv => true,
    version    => 'system',
  }

  class { '::memcached':
    max_memory => '60%',
    listen_ip  => '127.0.0.1',
  }

  vcsrepo { $elastic_recheck_dir :
    ensure   => latest,
    owner    => 'openstack_health',
    group    => 'openstack_health',
    provider => git,
    revision => $elastic_recheck_revision,
    source   => $elastic_recheck_repo,
    require  => Class['::openstack_health::user'],
  }

  package {'apache2-utils':
    ensure => present,
  }

  case $::osfamily {
    'RedHat': {
      package {'libffi-dev':
        ensure => present,
        name   => 'libffi-devel',
      }
    }
    default: {
      package {'libffi-dev':
        ensure => present,
      }
    }
  }

  package {'libxml2-dev':
    ensure => present,
  }

  package {'libxslt1-dev':
    ensure => present,
  }

  package {'zlib1g-dev':
    ensure => present,
  }

  package {'libmemcached-dev':
    ensure => present,
  }

  package {'cython':
    ensure => present,
  }

  exec { 'requirements-bin-pip':
    command     => "/usr/bin/pip install -U -r ${source_dir}/requirements.txt",
    onlyif      => 'test -f /usr/bin/pip',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    require     => [
      Package['libmemcached-dev'],
      Package['cython'],
    ],
    subscribe   => Vcsrepo[$source_dir],
    refreshonly => true,
    timeout     => 1800,
  }

  exec { 'elastic-recheck-install-bin-pip':
    command     => "/usr/bin/pip install -U ${elastic_recheck_dir}",
    onlyif      => 'test -f /usr/bin/pip',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    require     => [
      Package['libffi-dev'],
    ],
    subscribe   => Vcsrepo[$elastic_recheck_dir],
    refreshonly => true,
    timeout     => 1800,
  }

  exec { 'package-application-bin-pip':
    command     => "/usr/bin/pip install -U ${source_dir}",
    onlyif      => 'test -f /usr/bin/pip',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    require     => Exec['elastic-recheck-install'],
    subscribe   => Exec['requirements'],
  }

  exec { 'requirements-local-bin-pip':
    command     => "/usr/local/bin/pip install -U -r ${source_dir}/requirements.txt",
    onlyif      => 'test -f /usr/local/bin/pip',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    require     => [
      Package['libmemcached-dev'],
      Package['cython'],
    ],
    subscribe   => Vcsrepo[$source_dir],
    refreshonly => true,
    timeout     => 1800,
  }

  exec { 'elastic-recheck-install-local-bin-pip':
    command     => "/usr/local/bin/pip install -U ${elastic_recheck_dir}",
    onlyif      => 'test -f /usr/local/bin/pip',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    require     => [
      Package['libffi-dev'],
    ],
    subscribe   => Vcsrepo[$elastic_recheck_dir],
    refreshonly => true,
    timeout     => 1800,
  }

  exec { 'package-application-local-bin-pip':
    command     => "/usr/local/bin/pip install -U ${source_dir}",
    onlyif      => 'test -f /usr/local/bin/pip',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    require     => Exec['elastic-recheck-install'],
    subscribe   => Exec['requirements'],
  }

  file { '/etc/openstack-health.conf':
    ensure    => present,
    content   => template('openstack_health/openstack-health.conf.erb'),
    owner     => 'openstack_health',
    group     => 'openstack_health',
    mode      => '0644',
    subscribe => [
      Vcsrepo[$source_dir],
      Vcsrepo[$elastic_recheck_dir],
    ],
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
