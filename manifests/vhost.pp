# Install and maintain OpenStack Health.
# params:
#   serveradmin:
#     Used in the Apache virtual host, eg., openstack-health@openstack.org
#   vhost_name:
#     Used in the Apache virtual host, eg., health.openstack.org
#   vhost_port:
#     Used in the Apache virtual host, eg., 5000
#   api_endpoint:
#     The URL where openstack-health API is running
class openstack_health::vhost(
  $serveradmin = "webmaster@${::fqdn}",
  $vhost_name = 'localhost',
  $vhost_port = 80,
  $api_endpoint = 'http://localhost:5000',
) {

  class { '::openstack_health::frontend':
    api_endpoint => $api_endpoint
  }

  $frontend_dir = "${openstack_health::source_dir}/build"

  httpd::vhost { "${vhost_name}-frontend":
    docroot  => 'MEANINGLESS ARGUMENT',
    port     => $vhost_port,
    priority => '100',
    ssl      => false,
    template => 'openstack_health/openstack-health-frontend.vhost.erb',
    require  => Exec['build-static-files'],
  }
}
