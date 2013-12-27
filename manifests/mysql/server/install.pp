class oxid::mysql::server::install ($password, $override_options = $oxid::mysql::server::params::override_options) inherits 
oxid::mysql::server::params {
  class { 'mysql::server':
    root_password    => $password,
    override_options => $override_options
  }

  include mysql::server::mysqltuner
}