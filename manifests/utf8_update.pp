class oxid::utf8_update (
  $shop_dir        = $oxid::params::shop_dir,
  $compile_dir     = $oxid::params::compile_dir,
  $db_type         = $oxid::params::db_type,
  $db_host         = $oxid::params::db_host,
  $db_port         = $oxid::params::db_port,
  $db_name         = $oxid::params::db_name,
  $db_user         = $oxid::params::db_user,
  $db_password     = $oxid::params::db_password,
  $source          = undef,
  $repository      = $oxid::params::default_repository,
  $source_password = undef,
  $owner               = $apache::params::user,
  $group               = $apache::params::group,
  $sql_file = "utf8_EE.sql") inherits oxid::params {
  include 'stdlib'
  
  if !defined(Class[::mysql::client]) {
    class{::mysql::client:}
  }  
  
  $mysource = $source ? {
    undef   => $name,
    default => $source
  }

  $filename = inline_template('<%= File.basename(@mysource) %>')
  $archive_dir = "${oxid::params::tmp_dir}/${filename}"
  $php_file = inline_template("<%= File.join(@shop_dir, (0...32).map{ ('a'..'z').to_a[rand(26)] }.join + '_utf8-update.php') %>")

  oxid::repository::get { "${name}: get ${mysource}":
    source     => $mysource,
    repository => $repository
  }

  oxid::repository::unpack { "${name}: ${mysource}":
    repository  => $repository,
    source      => $mysource,
    destination => "${oxid::params::tmp_dir}/${filename}",
    password    => $source_password,
    require => Oxid::Repository::Get [ "${name}: get ${mysource}"]
  }

  exec { "cp -f ${archive_dir}/$sql_file ${shop_dir}/": path => $oxid::params::path, require => Oxid::Repository::Unpack["${name}: ${mysource}"]  }

  replace_all { "${shop_dir}/${sql_file}":
    file         => "${shop_dir}/${sql_file}",
    replacements => {
      "_NAME_OF_DB_" => "${db_name}"
    },
    require => Exec["cp -f ${archive_dir}/$sql_file ${shop_dir}/"] 
  }

  mysql_import { ["${shop_dir}/${sql_file}"]:
    db_host     => $db_host,
    db_port     => $db_port,
    db_user     => $db_user,
    db_password => $db_password,
    db_name     => $db_name,
    require     => [Class[::mysql::client], Replace_all["${shop_dir}/${sql_file}"]]
  }

  file { $php_file:
    ensure  => 'present',
    owner   => $user,
    group   => $group,
    mode    => "0755",
    content => template("oxid/oxid/php/utf8-update.erb")
  }

  oxid::php::runner { $php_file: source => $php_file, require =>  File[$php_file] }

  exec { "rm -f '${php_file}' '${sql_file}'": path => $oxid::params::path, require => [Oxid::Php::Runner[$php_file], Mysql_import["${shop_dir}/${sql_file}"]] }

  replace_all { "${name}: configure ${shop_dir}/config.inc.php":
    file         => "${shop_dir}/config.inc.php",
    replacements => {
      "\$this->iUtfMode[ ]*=[ ]*.*;" => "\$this->iUtfMode = '1';"
    }, require => Oxid::Php::Runner[$php_file]   
  }

  oxid::updateViews { $name:
          shop_dir    => $shop_dir,
          refreshonly => false,
          require     => Replace_all [ "${name}: configure ${shop_dir}/config.inc.php"]
  }      
}