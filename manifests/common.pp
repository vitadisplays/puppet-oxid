class oxid::common {
  include oxid::common::params
  
  class { 'apt':
    always_apt_update    => true,
  } ->
  
  package { $oxid::common::params::packages:  ensure => installed} 
}