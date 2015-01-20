# Class: oxid::mysql::server::install
#
# This class installs MySQL Server.
# For more information see https://forge.puppetlabs.com/puppetlabs/mysql
#
# Parameters:
#
# Actions:
#   - Install MySQL Server and mysqltuner
#   - Confugure my.cnf
#   - Manage MySQL service
#
# Requires:
#
# Sample Usage:
#  class {
#    'oxid::mysql::server::install':
#    password => "secret"
#  }
class oxid::mysql::server::install (
  $root_password,
  $old_root_password = '',
  $override_options = undef,
  $users            = undef,
  $grants           = undef,
  $databases        = undef) inherits oxid::mysql::server::params {

  $default_override_options = $oxid::mysql::server::params::override_options
  
  $default_databases = {
    "${oxid::params::db_name}" => {
      ensure  => 'present',
      charset => $oxid::mysql::server::params::latin_db_charset,
      collate => $oxid::mysql::server::params::latin_db_collation
    }
  }

  $default_users = {
    "${oxid::params::db_user}@localhost" => {
      ensure                   => 'present',
      max_connections_per_hour => '0',
      max_queries_per_hour     => '0',
      max_updates_per_hour     => '0',
      max_user_connections     => '0',
      password_hash            => mysql_password($oxid::params::db_password),
    }
  }

  $default_grants = {
    "${oxid::params::db_user}@${oxid::params::db_host}/${oxid::params::db_name}.*" => {
      ensure     => 'present',
      options    => ['GRANT'],
      privileges => ['ALL'],
      table      => "${oxid::params::db_name}.*",
      user       => "${oxid::params::db_user}@localhost",
    }
  }
  
  class { 'mysql::server':
    root_password    => $root_password,
    old_root_password    => $old_root_password,
    override_options        => $override_options ? {
      undef   => $default_override_options,
      default => $override_options
    },    
    databases        => $databases ? {
      undef   => $default_databases,
      default => $databases
    },
    users            => $users ? {
      undef   => $default_users,
      default => $users
    },
    grants           => $grants ? {
      undef   => $default_grants,
      default => $grants
    }
  }

  include mysql::server::mysqltuner
}