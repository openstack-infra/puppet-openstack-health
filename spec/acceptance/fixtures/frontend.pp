$application_dir = '/opt/openstack-health'

class { '::openstack_health':
  application_dir => $application_dir,
}

class { '::openstack_health::frontend':
  api_url         => 'localhost:5000',
  application_dir => $application_dir,
  vhost_name      => 'localhost',
  vhost_port      => '80',
}
