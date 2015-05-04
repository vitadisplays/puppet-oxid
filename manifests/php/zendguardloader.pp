require ::oxid::params

# Class: oxid::php::zendguardloader 
#
# This class installs Zend Guard.
#
# This class load and installs Zend Guard Extension for several PHP versions and OS Archtectures.
#
# Supported OS Archtectures: i386 and x86_64
# Supported PHP versions: 5.2, 5.3 and 5.4
#
# Parameters:
#
#   - php_dir               PHP config directory to install zenfgurad ini file. Default is "/etc/php5/apache2/conf.d".
#   - extension_dir         PHP extension directory to install library. Defaul is "/usr/local/zend/lib/php/extensions".
#   - version               PHP version for install Zend Guard. Supported Version are "5.2", "5.3" and "5.4". Default is "5.3".
#   - repository            Repository to load Zenda Guars archive from. Default is the predefined download location 'zend'.
#   - zend_optimizer_optimization_level   INI configuration. Default is 15.
#   - zend_loader_license_path            INI configuration. Default is ''.
#   - zend_loader_disable_licensing       INI configuration. Default is 0.
#   - ini_source            Your own INI configuration source. Default is undef.
#
# Actions:
#   - Download and install Zendguard
#   - Confugure zend_guard.ini
#
# Requires:
#
# Sample Usage:
#  class { 'oxid::php::install':  }
#
class oxid::php::zendguardloader (
  $php_dir       = "/etc/php5/apache2/conf.d",
  $extension_dir = "/usr/local/zend/lib/php/extensions",
  $version       = "5.3",
  $repository    = 'zend',
  $zend_optimizer_optimization_level = 15,
  $zend_loader_license_path          = "",
  $zend_loader_disable_licensing     = 0,
  $ini_source    = undef) {  
    
  if defined(Class['apache::mod::php']) {
    Class['apache::mod::php'] -> Oxid::Php::Zendguardloader <| |>
  }

  if defined(Service['httpd']) {
    Class[oxid::php::zendguardloader] ~> Service['httpd']
  }

  $inifile  = '/etc/php5/conf.d/20-zendguard.ini'
  $settings = {
    set => {
	      '.anon/zend_extension'          				=> $zend_loader_extension_file,
	      '.anon/zend_loader.enable'  					=> 1,
	      '.anon/zend_loader.disable_licensing'         => $zend_loader_disable_licensing,
	      '.anon/zend_optimizer.optimization_level'     => $zend_optimizer_optimization_level,
	      '.anon/zend_loader.license_path'   			=> $zend_loader_license_path
    }
  }
  
  $downloads = {
    "5.2-i386"   => "optimizer/3.3.9/ZendOptimizer-3.3.9-linux-glibc23-i386.tar.gz",
    "5.2-x86_64" => "optimizer/3.3.9/ZendOptimizer-3.3.9-linux-glibc23-x86_64.tar.gz",
    "5.3-i386"   => "guard/5.5.0/ZendGuardLoader-php-5.3-linux-glibc23-i386.tar.gz",
    "5.3-x86_64" => "guard/5.5.0/ZendGuardLoader-php-5.3-linux-glibc23-x86_64.tar.gz",
    "5.4-i386"   => "guard/6.0.0/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-i386.tar.gz",
    "5.4-x86_64" => "guard/6.0.0/ZendGuardLoader-70429-PHP-5.4-linux-glibc23-x86_64.tar.gz"
  }

  $supported_versions = ['5.2', '5.3', '5.4']
  $found = grep($supported_versions, $version)

  if count($found) == 0 {
    $supported_versions_str = join($supported_versions, ',')
    fail("Version ${version} is not supported, only following versions: ${supported_versions_str}")
  }

  $source = $downloads["${version}-${hardwaremodel}"]
  $download_basename = inline_template("<%= File.basename(@source) %>")
  $download_basename_without_extension = inline_template("<%= File.basename(@download_basename, '.tar.gz') %>")
  $version_dir = "php-${version}.x"
  $zend_loader_extension_file = "${extension_dir}/loader/${version_dir}/ZendGuardLoader.so"

  $repo_config = $oxid::params::repository_configs["${repository}"]
  $repo_dir = $repo_config['directory']

  $archive_file = inline_template("<%= File.join(@repo_dir, File.basename(@source)) %>")

  oxid::repository::get { $name:
    repository => $repository,
    source     => $source
  } ->
  exec { "mkdir -p '${extension_dir}/loader'":
    path   => $oxid::params::path,
    unless => "test -d $(dirname '${zend_loader_extension_file}')"
  } ->
  exec { "tar --directory ${extension_dir}/loader --strip-components=1 -zxvf ${archive_file} ${download_basename_without_extension}/${version_dir}/ZendGuardLoader.so"
  :
    path    => $oxid::params::path,
    unless  => "test -f '${zend_loader_extension_file}'",
    require => Class[oxid::package::packer]
  } ->
    
  php::config { 'php-extension-zendguard':
    inifile  => $inifile,
    settings => $settings
  }
}