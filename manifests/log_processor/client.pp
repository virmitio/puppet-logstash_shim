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

# == Class: log_processor::client
#
class logstash_shim::log_processor::client (
  $config_file = undef,
  $config_content = undef,
) {

  if !$config_file and !$config_content {
    fail('Must provide either $config_file or $config_content to this class.')
  }
  
#  if !defined(File['/etc/logstash']){
#    file { '/etc/logstash':
#      ensure => directory,
#      owner  => 'logstash',
#      group  => 'logstash',
#      mode   => '0644',
#    }
#  }

  file { '/etc/logstash/jenkins-log-client.yaml':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => $config_file,
    content => $config_content,
    require => File['/etc/logstash'],
  }

  file { '/etc/init.d/jenkins-log-client':
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0555',
    source  => 'puppet:///modules/log_processor/jenkins-log-client.init',
    require => [
      File['/usr/local/bin/log-gearman-client.py'],
      File['/etc/logstash/jenkins-log-client.yaml'],
    ],
  }

  service { 'jenkins-log-client':
    enable     => true,
    hasrestart => true,
    subscribe  => File['/etc/logstash/jenkins-log-client.yaml'],
    require    => File['/etc/init.d/jenkins-log-client'],
  }

  logrotate::rule { 'log-client-debug.log':
    path     => '/var/log/logstash/log-client-debug.log',
    compress => true,
    copytruncate => true,
    missingok => true,
    rotate => 7,
    rotate_every => 'day',
    ifempty => false,
    require => Service['jenkins-log-client'],
  }
}
