class oxid::apache::params {
  include ::apache::params
  
  $service_name = $::apache::params::service_name
  $user = $::apache::params::user
  $group = $::apache::params::group
}