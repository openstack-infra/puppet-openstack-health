# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health(
  $git_source_repo = 'https://git.openstack.org/openstack/openstack-health',
  $git_revision    = 'master',
  $application_dir = '/opt/openstack-health'
) {

  vcsrepo { $application_dir :
    ensure   => latest,
    provider => git,
    revision => $git_revision,
    source   => $git_source_repo,
  }

  class { '::openstack_health::api':
    application_dir => $application_dir,
    require         => Vcsrepo[$application_dir],
  }

  class { '::openstack_health::frontend':
    application_dir => $application_dir,
    require         => Vcsrepo[$application_dir],
  }
}
