# Install and maintain OpenStack Health.
# params:
#   application_dir:
#     The directory where the application will be running
class openstack_health(
  $git_source_repo = 'https://git.openstack.org/openstack/openstack-health',
  $git_revision    = 'master',
  $application_dir = '/opt/openstack-health'
) {

  include ::httpd

  vcsrepo { $application_dir :
    ensure   => latest,
    provider => git,
    revision => $git_revision,
    source   => $git_source_repo,
  }
}
