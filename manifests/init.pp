# Install and maintain OpenStack Health.
# params:
#   source_dir:
#     The directory where the application will be running
#   git_source_repo:
#     Source code repository
#   git_revision:
#     Branch or tag that will be deployed
class openstack_health(
  $git_revision    = 'master',
  $git_source_repo = 'https://git.openstack.org/openstack/openstack-health',
  $source_dir      = '/opt/openstack-health',
) {

  include ::httpd
  include ::openstack_health::user

  vcsrepo { $source_dir :
    ensure   => latest,
    owner    => 'openstack_health',
    group    => 'openstack_health',
    provider => git,
    revision => $git_revision,
    source   => $git_source_repo,
    require  => Class['::openstack_health::user'],
  }
}
