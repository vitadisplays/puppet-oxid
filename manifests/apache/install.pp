# Class: oxid::apache::install
#
# This class installs Apache
#
# Parameters:
#
# Actions:
#   - Install Apache
#   - Install Modules
#   - Confugure VHosts, including ssl VHost
#   - Manage Apache service
#
# Requires:
#
# Sample Usage:
#  class { 'oxid::apache::install':
#     servername => $hostname,
#     docroot => '/srv/www/oxid'
#  }
class oxid::apache::install (
  $docroot           = $oxid::params::shop_dir,
  $servername        = $hostname,
  $ip                = $ipaddress,
  $vhost_name        = '*',
  $default_mods      = true,
  $default_vhost     = false,
  $default_ssl_vhost = false,  
  $ssl               = true,
  $ssl_cert          = undef,
  $ssl_key           = undef) {
  include apache::params

  if !defined(Class[oxid::apt]) {
    include oxid::apt
  }

  host { "${servername}": ip => $ip; }

  class { "::apache":
    default_mods      => true,
    default_vhost     => false,
    default_ssl_vhost => false,
    mpm_module        => "prefork"
  }

  include apache::mod::php
  include apache::mod::rewrite
  include apache::mod::vhost_alias
  include apache::mod::deflate
  include apache::mod::headers
  include apache::mod::expires

  apache::vhost { "oxid":
    servername    => $servername,
    docroot       => $docroot,
    default_vhost => true,
    vhost_name    => $vhost_name,
    port          => 80,
    docroot_owner => $apache::params::user,
    docroot_group => $apache::params::group,
    options       => ['Indexes', 'FollowSymLinks', 'MultiViews'],
    override      => 'All'
  }

  if $ssl {
    apache::vhost { 'oxid-ssl':
      servername    => $servername,
      port          => '443',
      docroot       => $docroot,
      vhost_name    => $vhost_name,
      ssl           => true,
      ssl_cert      => $ssl_cert,
      ssl_key       => $ssl_key,
      docroot_owner => $apache::params::user,
      docroot_group => $apache::params::group,
      options       => ['Indexes', 'FollowSymLinks', 'MultiViews'],
      override      => 'All'
    }
  }
}