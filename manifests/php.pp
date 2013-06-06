class oxid::php {
  include oxid::php::params
  $module_path = get_module_path('oxid')

  package { $oxid::php::params::packages: ensure => installed, require => Package["apache2"] } ->   
  
  pear{ $oxid::php::params::pear_packages: } ->
  
  file { ["/usr/local/zend/", "/usr/local/zend/lib/", "/usr/local/zend/lib/php/", "/usr/local/zend/lib/php/extensions/"]:
    owner   => "root",
    group   => "root",
    ensure => "directory"
  } ->
  
  file { "/usr/local/zend/lib/php/extensions/ZendGuardLoader.so":
    owner   => "root",
    group   => "root",
    source  => "${module_path}/files/zend/php-5.3.x/ZendGuardLoader.so",
    ensure => "directory"
  } ->

  file { "/etc/php53/apache2/conf.d/zend_guard.ini":
    owner   => "root",
    group   => "root",
    source  => "${module_path}/files/zend/zend_guard.ini",
    notify => Exec["force-reload-apache2"]
  } ->
  
  file { $oxid::php::params::config:
    ensure  => present 
  } 
  
  define pear() {
    exec { "pear install ${name}":
      path   => "/usr/bin:/usr/sbin:/bin",
      require => Package["php53-pear"],
      unless => "pear info ${name}"
    }
  } 
}