class oxid::php::params {
  $packages = [
    'php5',
    'php5-cli',
    'php-apc',
    'php-pear',
    'php5-common',
    'php5-dev',
    'php5-gd',
    'php5-imagick',
    'php5-mcrypt',
    'php5-memcache',
    'php5-memcached',
    'php5-mysql',
    'php5-curl',
    'shtool',
    'ssl-cert',
    'uuid-dev', "libapache2-mod-php5"]
    
    $config = "/etc/php5/apache2/php.ini"
}

class oxid::mysql::params {
  $server_package_name = "mysql-server"
  $packages = [$server_package_name, "mysqltuner"]
}

class oxid::params {
  $db_host = "localhost"
  $db_port = 3361
  $db_name = "oxid"
  $db_user = "oxid"
  $db_password = "oxid"
  
  $shop_dir = "/srv/www/oxid"
  $compile_dir = "/srv/www/oxid/tmp"

  $config_key = 'fq45QS09_fqyx09239QQ'
}

class oxid::apache::params {
  $user = "www-data"
  $group = "www-data"
  $mods_enabled = ["php5", "rewrite", "deflate", "headers", "expires", "ssl"]
  $mods_disabled = []
  $packages = ["apache2"]
  $apache2_sites = "/etc/apache2/sites"
  $apache2_mods = "/etc/apache2/mods"
}

class oxid::common::params {
  $tmp_dir = "/tmp"
  $packages = [	   
	  'python-software-properties', 
	  'gzip', 
	  'zip',
	  'mysql-client',
	  'expect']
}