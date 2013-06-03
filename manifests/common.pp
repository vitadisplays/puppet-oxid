class oxid::common() {
  include oxid::common::params
  
  class { 'apt':
    always_apt_update    => true,
  }

  apt::ppa { "ppa:skettler/php": }
  
  /*exec { "apt-get update": 
    path => "/usr/bin:/usr/sbin:/bin"
  } ->*/
  
  package { $oxid::common::params::packages:  ensure => installed, require => Class['apt'] } 
}