# Copyright 2013 Hewlett-Packard Development Company, L.P.
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
#
# Logstash web frontend glue class.
#
class logstash_shim (
  $enable_recheck = false,
  $gerrit_host,
  $gerrit_ssh_private_key,
  $gerrit_ssh_private_key_contents,
  #not used today, will be used when elastic-recheck supports it.
  $elasticsearch_url,
  $recheck_bot_passwd,
  $recheck_bot_nick = 'openstackrecheck',
#  $elasticsearch_nodes = [],
#  $gearman_workers = [],
  $discover_nodes = ['elasticsearch.openstack.org:9200'],
#  $sysadmins = []
) {
#  $iptables_es_rule = regsubst ($elasticsearch_nodes, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 9200:9400 -s \1 -j ACCEPT')
#  $iptables_gm_rule = regsubst ($gearman_workers, '^(.*)$', '-m state --state NEW -m tcp -p tcp --dport 4730 -s \1 -j ACCEPT')
#  $iptables_rule = flatten([$iptables_es_rule, $iptables_gm_rule])
#  class { 'openstack_project::server':
#    iptables_public_tcp_ports => [22, 80],
#    iptables_rules6           => $iptables_rule,
#    iptables_rules4           => $iptables_rule,
#    sysadmins                 => $sysadmins,
#  }

  class { 'logstash::web':
    frontend            => 'kibana',
    discover_nodes      => $discover_nodes,
    proxy_elasticsearch => true,
  }

  include apache
  include apache::mod::proxy
  include apache::mod::proxy_http
  include apache::mod::rewrite
  
  $inst_java = !defined(Class['Java'])
    
  class { 'logstash':
    java_install => $inst_java,
  }
  
  $rewrite_node = $discover_nodes[0]
  $rewrites = [
    {rewrite_cond => ['%{REQUEST_METHOD} GET'], 
     rewrite_rule => ["^/elasticsearch/(_aliases|(.*/)?_status|(.*/)?_search|(.*/)?_mapping|_cluster/health|_nodes)\$ http://${rewrite_node}/\$1 [P]"]},
    {rewrite_cond => ['%{REQUEST_METHOD} POST'],
     rewrite_rule => ["^/elasticsearch/(_aliases|(.*/)?_search)\$ http://${rewrite_node}/\$1 [P]"]},
    {rewrite_cond => ['%{REQUEST_METHOD} OPTIONS'],
     rewrite_rule => ["^/elasticsearch/((.*/)?_search)\$ http://${rewrite_node}/\$1 [P]"]}]
  
  $custom_proxy = "
<Proxy http://${rewrite_node}/>
  ProxySet connectiontimeout=15 timeout=120
</Proxy>
ProxyPassReverse /elasticsearch/ http://${rewrite_node}/
ProxyPass / http://127.0.0.1:5601/ retry=0
ProxyPassReverse / http://127.0.0.1:5601/
"
  
  apache::vhost { $::fqdn:
    port => 80,
    priority => 50,
    docroot => '/usr/local/src/logstash_docroot',
    log_level => 'warn',
    rewrites => $rewrites,
    custom_fragment => $custom_proxy,
  }
  
  class { 'kibana': }
  
  class { 'logstash_shim::log_processor': }

  class { 'logstash_shim::log_processor::client':
    config_file => 'puppet:///modules/openstack_project/logstash/jenkins-log-client.yaml',
  }

  if $enable_recheck {
    class { 'logstash_shim::elastic_recheck::bot':
      gerrit_host                     => $gerrit_host,
      gerrit_ssh_private_key          => $gerrit_ssh_private_key,
      gerrit_ssh_private_key_contents => $gerrit_ssh_private_key_contents,
      elasticsearch_url               => $elasticsearch_url,
      recheck_bot_passwd              => $recheck_bot_passwd,
      recheck_bot_nick                => $recheck_bot_nick,
    }
  }
}
