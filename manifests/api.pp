# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health::api(
  $application_dir = undef,
  $serveradmin = "webmaster@${::fqdn}",
  $vhost_name = localhost,
  $vhost_port = 5000,
) {

  include ::httpd::mod::wsgi

  $api_dir = "${application_dir}/openstack_health"
  $virtualenv_dir = "${application_dir}/.venv"
  $gunicorn_bind = 'localhost:8081'

  class { '::python':
    dev        => true,
    gunicorn   => true,
    pip        => true,
    version    => 'system',
    virtualenv => true,
  }

  ::python::virtualenv { $virtualenv_dir:
    ensure => present,
  }

  ::python::pip { 'gunicorn':
    ensure     => '17.5',
    virtualenv => $virtualenv_dir,
    require    => Python::Virtualenv[$virtualenv_dir],
  }

  ::python::requirements { "${application_dir}/requirements.txt":
    virtualenv => $virtualenv_dir,
    cwd        => $application_dir,
    require    => Python::Virtualenv[$virtualenv_dir],
    subscribe  => Vcsrepo[$application_dir],
  }

  ::httpd::vhost { "${vhost_name}-api":
    docroot  => 'meaningless argument',
    port     => 5000,
    priority => '50',
    require  => Python::Requirements["${application_dir}/requirements.txt"],
    template => 'openstack_health/openstack-health-api.vhost.erb',
    ssl      => false,
  }
}
