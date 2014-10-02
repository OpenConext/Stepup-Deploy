stage { 'aptgetupdate':
  before => Stage['main'],
}

class { 'repos':
  stage        => 'aptgetupdate',
}

class { 'apt':
}

package { [ "ruby-gelf", "curl", "moreutils", 'openjdk-7-jre-headless' ]:
  ensure => latest,
}

class { 'apache':
}

file { '/var/www/graylog2-stream-dashboard':
  ensure  => link,
  target  => '/usr/share/graylog2-stream-dashboard',
  require => Class['apache'],
}

class {'::mongodb::globals':
  manage_package_repo => false,
  }->
class {'::mongodb::server':
  noauth     => true,
  fork       => false,
  oplog_size => 10,
} ->
class { 'elasticsearch':
  config                 => {
    'cluster'            => {
      'name'             => 'graylog2'
    }
  },
  package_url => 'https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.10.deb',
  require     => Package['openjdk-7-jre-headless'],
} ->
class {'graylog2::repo':
  version => '0.90',
} ->
class {'graylog2::server':
  password_secret    => 'kuY4TrWvjYeh3yqrUPXvgtN2fk9ErquTuQFtqiswYF8OhPYoQbNkjQXJuXSXuMzGpUz97v2gl9tImrFnpQZG670cBf0QOlLG',
  root_password_sha2 => 'e3c652f0ba0b4801205814f8b6bc49672c4c74e25b497770bb89b22cdeb4e951',
  rest_enable_cors   => true,
  rest_listen_uri    => "http://${::ipaddress}:12900/",
  rest_transport_uri => "http://${::ipaddress}:12900/",
  elasticsearch_discovery_zen_ping_multicast_enabled => false,
  elasticsearch_discovery_zen_ping_unicast_hosts     => '127.0.0.1:9300',
} ->
class {'graylog2::web':
  application_secret   => 'G3n133XvTHhvhkEWNMLUgKk0BaYAcpN85eJggjsCr5yyViwuq7y2Bs6U88xHmfG33e5r3IjE38padqS3S49QMRZ8pzZgndfL',
  graylog2_server_uris => [ "http://${::ipaddress}:12900/" ],
} ->
class {'graylog2::dashboard':
} ->
file { '/usr/local/bin/create_graylog2_inputs_gelf':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
  source => 'puppet:///modules/repos/create_graylog2_inputs_gelf',
} ->
exec { 'create_gelf_udp_tcp_inputs':
  command   => '/usr/local/bin/create_graylog2_inputs_gelf',
}

file { '/usr/local/create_test_message':
  ensure => present,
  owner  => 'root',
  group  => 'root',
  mode   => '0755',
  source => 'puppet:///modules/repos/create_test_message',
}

cron { 'create_test_messages':
  ensure  => present,
  command => '/usr/local/create_test_message > /dev/null 2>&1',
  minute  => '*',
  user    => 'root',
}
