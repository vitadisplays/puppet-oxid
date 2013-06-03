class oxid::php::params {
  $packages = [
    'php53',
    'php53-dev',
    'php53-apc',
    'php53-pear',
    'php53-common',
    'php53-memcache',
    'shtool',
    'ssl-cert',
    'uuid-dev', "libapache2-mod-php53"]    
    
  $pear_packages = ['MDB2_Driver_mysql', 'Net_Curl']
  $config = "/etc/php53/apache2/php.ini"
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
	  'gzip', 
	  'zip',
	  'mysql-client',
	  'expect']
}