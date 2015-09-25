# Install and maintain OpenStack Health.
# params:
#   api_url:
#     The url where the openstack-health api will be running
#   application_dir:
#     The directory where the application will be running
#   serveradmin:
#     Used in the Apache virtual host, eg., openstack-health@openstack.org
#   vhost_name:
#     Used in the Apache virtual host, eg., health.openstack.org
class openstack_health::frontend(
  $api_url = undef,
  $application_dir = undef,
  $serveradmin = "webmaster@${::fqdn}",
  $vhost_name = localhost,
  $vhost_port = 80,
) {

  $frontend_dir = "${application_dir}/build"

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

  # There isn't a way of doing that with puppet-nodejs yet.
  # See: https://github.com/puppet-community/puppet-nodejs/issues/154
  exec { 'install-frontend-requirements':
    command   => 'npm install',
    cwd       => $application_dir,
    path      => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    # Increasing the timeout due to the amount of dependencies downloaded.
    require   => [
      Package['gulp'],
      Package['node-gyp'],
    ],
    subscribe => Vcsrepo[$application_dir],
    timeout   => 600,
  }

  exec { 'build-static-files':
    command   => 'gulp prod',
    cwd       => $application_dir,
    path      => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    require   => Exec['install-frontend-requirements'],
    subscribe => Vcsrepo[$application_dir],
  }

  ::httpd::vhost { "${vhost_name}-frontend":
    docroot  => 'meaningless argument',
    port     => 80,
    priority => '100',
    require  => Exec['build-static-files'],
    template => 'openstack_health/openstack-health-frontend.vhost.erb',
    ssl      => false,
  }
}
