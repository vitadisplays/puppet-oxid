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
class oxid::mysql::server::install ($password, $override_options = $oxid::mysql::server::params::override_options) inherits 
oxid::mysql::server::params {
  class { 'mysql::server':
    root_password    => $password,
    override_options => $override_options
  }

  include mysql::server::mysqltuner
}