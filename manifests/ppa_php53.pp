class oxid::ppa_php53 {
  /*apt::ppa { "ppa:skettler/php": } -> 
  
    package { 'php53':
    ensure  => installed,
    require => [Package["apache2"]],
    alias   => "php"
  } -> 
  
  class {apache2: } ->
  
  package { [
    'php53-dev',
    'php53-apc',
    'php53-pear',
    'php53-common',
    'php53-memcache',
    'libapache2-mod-php53']:
    ensure  => installed,
    require => [Package["apache2"]]
  } -> 
  
  php::pear { ['MDB2_Driver_mysql', 'Net_Curl']: }  -> 
  
  oxid::php::zend_guard_loader_install { "zend-guard-loader":
    ensure    => "present",
    confd_dir => "/etc/php53/apache2/conf.d"
  } ->
  
  apache2::module { "php53": package_require => "libapache2-mod-php53" }*/
}