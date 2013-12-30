class oxid::php::install (
  $ensure   = $oxid::php::params::ensure,
  $package  = $oxid::php::params::package,
  $provider = $oxid::php::params::provider,
  $inifile  = $oxid::php::params::inifile,
  $settings = $oxid::php::params::settings,
  $dotdeb   = false) inherits oxid::php::params {
  if !defined(Class[php::apt]) {
    if $dotdeb == true {
      include php::apt
    }
  }
 
  if !defined(Class[oxid::apt]) {
    include oxid::apt
  }

  if !defined(Class['augeas']) {
    include augeas
  }

  if !defined(Class['php']) {
    include php
  }

  if !defined(Class['php::cli']) {
    class { 'php::cli': ensure => $ensure }
  }

  if !defined(Class['php::apache']) {
    class { 'php::apache':
      ensure   => $ensure,
      package  => $package,
      provider => $provider,
      inifile  => $inifile,
      settings => $settings
    }
  }

  if !defined(Class['php::extension::gd']) {
    class { 'php::extension::gd': ensure => $ensure }
  }

  if !defined(Class['php::extension::mysql']) {
    class { 'php::extension::mysql': ensure => $ensure }
  }

  if !defined(Class['php::extension::curl']) {
    class { 'php::extension::curl': ensure => $ensure }
  }
}