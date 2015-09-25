$application_dir = '/opt/openstack-health'

class { '::openstack_health':
  application_dir => $application_dir,
}

class { '::openstack_health::api':
  application_dir => $application_dir,
  vhost_name      => 'localhost',
  vhost_port      => '5000',
}
