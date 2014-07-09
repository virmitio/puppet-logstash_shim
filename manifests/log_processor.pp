# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2013 OpenStack Foundation
# Copyright 2014 Tim Rogers
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

# == Class: log_processor
#
class logstash_shim::log_processor (
  $classifier_source = 'puppet:///modules/logstash_shim/default-classify-log.crm',
  $gearman_client_script_source = 'puppet:///modules/logstash_shim/default-log-gearman-client.py',
  $gearman_worker_script_source = 'puppet:///modules/logstash_shim/default-log-gearman-worker.py',
  $classifier_template = undef,
  $gearman_client_script_template = undef,
  $gearman_worker_script_template = undef,
) {

#  if !defined(Package['python-daemon']){
    package { 'python-daemon':
      ensure => present,
    }
#  }
  
#  if !defined(Package['python-zmq']){
    package { 'python-zmq':
      ensure => present,
    }
#  }
  
#  if !defined(Package['python-yaml']){
    package { 'python-yaml':
      ensure => present,
    }
#  }
  
#  if !defined(Package['crm114']){
    package { 'crm114':
      ensure => present,
    }
#  }

  if !defined(Class['python']){
    class { 'python':
      pip    => true,
    }
  }

#  if !defined(Package['gear']){
    package { 'gear':
      ensure   => latest,
      provider => 'pip',
      require  => Class['python'],
    }
#  }

  file { '/var/lib/crm114':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
  }
  
  if $classifier_template {
    $real_classifier_source = undef
  } else {
    $real_classifier_source = $classifier_source
  }
  if $gearman_client_script_template {
    $real_gearman_client_script_source = undef
  } else {
    $real_gearman_client_script_source = $gearman_client_script_source
  }
  if $gearman_worker_script_template {
    $real_gearman_worker_script_source = undef
  } else {
    $real_gearman_worker_script_source = $gearman_worker_script_source
  }

  file { '/usr/local/bin/classify-log.crm':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => $real_classifier_source,
    content => $classifier_template,
    require => [
      Package['crm114'],
    ],
  }

  file { '/usr/local/bin/log-gearman-client.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => $real_gearman_client_script_source,
    content => $gearman_client_script_template,
    require => [
      Package['python-daemon'],
      Package['python-zmq'],
      Package['python-yaml'],
      Package['gear'],
    ],
  }

  file { '/usr/local/bin/log-gearman-worker.py':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    source  => $real_gearman_worker_script_source,
    content => $gearman_worker_script_template,
    require => [
      Package['python-daemon'],
      Package['python-zmq'],
      Package['python-yaml'],
      Package['gear'],
    ],
  }
}
