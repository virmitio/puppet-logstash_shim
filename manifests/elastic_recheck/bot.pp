# Copyright 2013 Hewlett-Packard Development Company, L.P.
# Copyright 2013 Samsung Electronics
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
class logstash_shim::elastic_recheck::bot (
  $recheck_config_content = undef,
  $gerrit_host,
  $gerrit_ssh_private_key,
  $gerrit_ssh_private_key_contents,
  #not used today, will be used when elastic-recheck supports it.
  $elasticsearch_url,
  $recheck_bot_passwd,
  $gerrit_user = 'elasticrecheck',
  $recheck_bot_nick = 'openstackrecheck',
) {
  include logstash_shim::elastic_recheck
  
  if $recheck_config_content{
    $real_recheck_config_content = $recheck_config_content
  } else {
    $real_recheck_config_content = template('logstash_shim/elastic-recheck.conf.erb')
  }

  file { '/etc/elastic-recheck/elastic-recheck.conf':
    ensure  => present,
    mode    => '0640',
    owner   => 'recheck',
    group   => 'recheck',
    content => $real_recheck_config_content,
    require => Class['elastic_recheck'],
  }

  file { '/home/recheck':
    ensure  => directory,
    mode    => '0700',
    owner   => 'recheck',
    group   => 'recheck',
    require => Class['elastic_recheck'],
  }

  file { '/home/recheck/.ssh':
    ensure  => directory,
    mode    => '0700',
    owner   => 'recheck',
    group   => 'recheck',
    require => Class['elastic_recheck'],
  }

  file { $gerrit_ssh_private_key:
    ensure  => present,
    mode    => '0600',
    owner   => 'recheck',
    group   => 'recheck',
    content => $gerrit_ssh_private_key_contents,
    require => Class['elastic_recheck'],
  }

  file { '/etc/init.d/elastic-recheck':
    ensure => present,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/logstash_shim/elastic-recheck.init',
  }

  service { 'elastic-recheck':
    ensure    => running,
    enable    => true,
    subscribe => [
      File['/etc/elastic-recheck/elastic-recheck.conf'],
      Exec['install_elastic-recheck'],
    ],
    require   => [
      Class['elastic_recheck'],
      File['/etc/init.d/elastic-recheck'],
      File['/etc/elastic-recheck/elastic-recheck.conf'],
    ],
  }
}
