class oxid::mysql::server::install ($password, $override_options = undef) inherits 
oxid::mysql::params {
  class { 'mysql::server':
    root_password    => $password,
    override_options => $override_options
  }

  include mysql::server::mysqltuner
}