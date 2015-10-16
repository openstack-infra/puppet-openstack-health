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
# == Define: openstack_health::site
#

define openstack_health::site(
    $httproot,
    $api_endpoint = 'http://localhost:5000'
) {

  class { '::openstack_health::frontend':
    api_endpoint => $api_endpoint
  }

  exec {'move-static-files':
    command   => "mv ${openstack_health::source_dir}/build ${httproot}",
    path      => ['/usr/local/bin/', '/usr/bin/', '/bin/'],
    subscribe => Exec['build-static-files']
  }

  file {$httproot:
    ensure  => directory,
    owner   => 'openstack_health',
    group   => 'openstack_health',
    mode    => '0755',
    require => Exec['move-static-files']
  }
}
