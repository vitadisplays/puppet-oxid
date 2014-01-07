class oxid::params {
  $shop_dir = "/srv/www/oxid"
  $compile_dir = "${shop_dir}/tmp"

  $shop_url = "http://${hostname}"

  $shop_ssl_url = undef
  $admin_ssl_url = undef

  $db_type = "mysql"
  $db_host = "localhost"
  $db_port = 3306
  $db_name = "oxid"
  $db_user = "oxid"
  $db_password = "oxid"

  $default_charset = "latin1"

  $utf8_mode = 0

  $rewrite_base = "/"

  $mysql_user = "root"
  $mysql_password = ""

  $default_shopid = ''
  $config_key = 'fq45QS09_fqyx09239QQ'

  $apache_mods = ['vhost_alias', 'php5', 'rewrite', 'headers']

  $packages = ['shtool', 'ssl-cert', 'uuid-dev']

  $tmp_dir = "/tmp/oxid"

  $path = "/usr/bin:/usr/sbin:/bin"

  $default_remote_dump_options_latin1 = [
    "--single-transaction",
    "--add-drop-table",
    "--create-options",
    "--allow-keywords",
    "--hex-blob",
    "--default-character-set=latin1"]

  $default_remote_dump_options_utf8 = [
    "--single-transaction",
    "--add-drop-table",
    "--create-options",
    "--allow-keywords",
    "--hex-blob",
    "--default-character-set=utf8"]

  $default_repository = 'none'
  $zend_repository = 'zend'
  $repository_configs = {
    "${default_repository}" => {
      'type'      => 'oxid::repository::file',
      'directory' => ''
    }
    ,
    "${zend_repository}"    => {
      'type'       => 'oxid::repository::wget',
      'directory'  => "${tmp_dir}/repository/${zend_repository}",
      'url'        => 'http://downloads.zend.com',
      'timeout'    => 300,
      'verbose'    => false,
      'redownload' => false
    }
  }

  $supported_archives = [".phar", ".zip", ".tar.gz", "tgz", ".gz", ".bz2", ".rar"]

  $default_module_copy_map = {
    'copy_this/'    => '',
    'changed_full/' => ''
  }
}