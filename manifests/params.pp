/*class oxid::php::params {
  $config = "/etc/php53/apache2/php.ini"
}*/

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

  $config_key = 'fq45QS09_fqyx09239QQ'
}

class oxid::apache2::params {
  $user = "www-data"
  $group = "www-data"
  $packages = ['php5', 'php5-dev', 'php5-gd', 'php-apc', 'php-pear', 'php5-common', 'php5-mysql', 'php5-curl', 'php5-memcache', 'libapache2-mod-php5']
  $sites_path = "/etc/apache2/sites"
  $mods_path = "/etc/apache2/mods"
}

class oxid::zend_server::params inherits oxid::apache2::params {
 $user = "www-data"
 $group = "www-data"
 $packages = [
    'php-5.3-dev-zend-server',
    'php-5.3-mssql-zend-server',
    'php-5.3-pdo-mysql-zend-server',
    'php-5.3-curl-zend-server',
    'php-5.3-gd-zend-server',
    'php-5.3-imagick-zend-server',
    'php-5.3-bcmath-zend-server',
    'php-5.3-mbstring-zend-server',
    'php-5.3-mcrypt-zend-server',
    'php-5.3-apc-zend-server',
    'php-5.3-memcache-zend-server',
    'php-5.3-xmlrpc-zend-server',
    'libapache2-mod-php-5.3-zend-server']
  $sites_path = "/etc/apache2/sites"
  $mods_path = "/etc/apache2/mods"
}

class oxid::common::params {
  $tmp_dir = "/tmp"
  $packages = [	   
	  'gzip', 
	  'zip',
	  'unzip',
	  'mysql-client',
	  'expect','shtool',
    'ssl-cert',
    'uuid-dev']
}