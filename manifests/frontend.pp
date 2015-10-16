# Install and maintain OpenStack Health.
# params:
#   source_dir:
#     The directory where the application will be running

class openstack_health::frontend(
  $source_dir = '/opt/openstack-health',
  $api_endpoint,
) {

  class { '::nodejs':
    legacy_debian_symlinks => true,
    repo_url_suffix        => 'node_0.12',
  }

  package { 'node-gyp':
    ensure   => present,
    provider => npm,
    require  => Class['::nodejs'],
  }

  package { 'gulp':
    ensure   => present,
    provider => npm,
    require  => Class['::nodejs'],
  }

  exec { 'install-frontend-requirements':
    command   => 'npm install',
    cwd       => $source_dir,
    path      => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    timeout   => 900,
    require   => [
      Package['gulp'],
      Package['node-gyp'],
    ],
    subscribe => Vcsrepo[$source_dir],
  }

  exec { 'build-static-files':
    command   => 'gulp prod',
    cwd       => $source_dir,
    path      => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    require   => Exec['install-frontend-requirements'],
    subscribe => Vcsrepo[$source_dir],
  }

  file { "${source_dir}/build/config.json":
      ensure  => present,
      owner   => 'openstack_health',
      group   => 'openstack_health',
      mode    => '0755',
      content => template('openstack_health/config.json.erb'),
      require => Exec['build-static-files']
  }

}
