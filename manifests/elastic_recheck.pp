# Copyright 2013 Hewlett-Packard Development Company, L.P.
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
# Class to install and configure an instance of the elastic-recheck
# service.
#
class logstash_shim::elastic_recheck (
  $recheck_repo = 'https://git.openstack.org/openstack-infra/elastic-recheck',
  $logging_config_source = 'puppet:///modules/logstash_shim/logging.config',
  $logging_config_content = undef,
  $bot_config_source = 'puppet:///modules/logstash_shim/recheckwatchbot.yaml',
  $bot_config_content = undef,
) {
  group { 'recheck':
    ensure => 'present',
  }

  user { 'recheck':
    ensure  => present,
    home    => '/home/recheck',
    shell   => '/bin/bash',
    gid     => 'recheck',
    require => Group['recheck'],
  }

  vcsrepo { '/opt/elastic-recheck':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => $recheck_repo,
  }

#  if !defined(Package['python']){
    package { 'python':
      ensure => present,
      pip    => true,
    }
#  }

  if $logging_config_content {
    $real_logging_config_source = undef,
  } else {
    $real_logging_config_source = $logging_config_source,
  }
  if $bot_config_content {
    $real_bot_config_source = undef,
  } else {
    $real_bot_config_source = $bot_config_source,
  }


  exec { 'install_elastic-recheck' :
    command     => 'pip install /opt/elastic-recheck',
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/elastic-recheck'],
    require     => Class['pip'],
  }

  file { '/var/run/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/var/lib/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/var/log/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/etc/elastic-recheck':
    ensure  => directory,
    mode    => '0755',
    owner   => 'recheck',
    group   => 'recheck',
    require => User['recheck'],
  }

  file { '/etc/elastic-recheck/logging.config':
    ensure  => present,
    mode    => '0640',
    owner   => 'recheck',
    group   => 'recheck',
    source  => $real_logging_config_source,
    content => $logging_config_content,
    require => File['/etc/elastic-recheck'],
  }

  file { '/etc/elastic-recheck/recheckwatchbot.yaml':
    ensure  => present,
    mode    => '0640',
    owner   => 'recheck',
    group   => 'recheck',
    source  => $real_bot_config_source,
    content => $bot_config_content,
    require => File['/etc/elastic-recheck'],
  }

  file { '/etc/elastic-recheck/queries':
    ensure  => link,
    target  => '/opt/elastic-recheck/queries',
    require => [
      Vcsrepo['/opt/elastic-recheck'],
      File['/etc/elastic-recheck'],
    ],
  }
}
