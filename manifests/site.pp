# Copyright (c) 2014 Hewlett-Packard Development Company, L.P.
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# == Define: openstack_health
#
define openstack_health::site(
	$configfile,
	$httproot,
	$serveradmin = undef
) {

 $frontend_dir = "${source_dir}/build"

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
    cwd       => $httproot,
    path      => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    require   => Exec['install-frontend-requirements'],
    subscribe => Vcsrepo[$source_dir],
  }
  file {$httproot:
    ensure => directory,
    owner  => 'openstack_health',
    group  => 'openstack_health',
    mode   => '0755',
  }
}
