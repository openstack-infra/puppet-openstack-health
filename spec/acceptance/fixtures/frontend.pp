$source_dir = '/opt/openstack-health'

class { '::openstack_health':
  source_dir => $source_dir,
}

class { '::openstack_health::vhost':
  serveradmin  => "webmaster@${::fqdn}",
  vhost_name   => 'localhost',
  vhost_port   => 80,
  api_endpoint => 'http://localhost:5000',
}
