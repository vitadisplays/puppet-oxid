class oxid::common() {
  include oxid::common::params
  
  exec { "apt-get update": 
    path => "/usr/bin:/usr/sbin:/bin"
  } ->
  
  package { $oxid::common::params::packages:  ensure => installed, } 
}