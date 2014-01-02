import "utils.pp"
import "config.pp"
import "remote-utils.pp"
import "php/zendguardloader.pp"

# Class: oxid
#
# This class installs Oxid.
#
# Parameters:
#
#   - repository          The repository to get from
#   - source            The location of the setup archive in the defined repository. For output mapping use a hash, like {
#   "index.php" => "OXID_ESHOP_CE_CURRENT.zip"}. This will download index.php to download file OXID_ESHOP_CE_CURRENT.zip. Helpfully
#   to download from oxid default location.
#   - purge             If true, deletes the shop dir.
#   - shop_dir            The oxid shop directroy
#   - compile_dir         The oxid compile directroy
#   - db_type           Default is mysql and is only supported type.
#   - db_host           Oxid database host
#   - db_name           Oxid database name
#   - db_user           Oxid database user
#   - db_password         Oxid database password
#   - shop_url            Oxid shop url
#   - shop_ssl_url          Oxid shop ssl url
#   - admin_ssl_url         Oxid admin ssl url
#   - sql_charset         The chaset of the sql files. Default latin1.
#   - mysql_user          MySQL User to prepare database
#   - mysql_password        MySQL password
#   - rewrite_base          Rewrite Base in the .htaccess file
#   - config_content        Your own oxyid configuration content
#   - htaccess_content        Your own htaccess configuration content
#   - config_source         Your own oxid configuration source
#   - htaccess_source       Your own oxid htaccess source
#   - config_extra_replacements   Extra replacements for oxid configuration. Example:
#   {"\$this->sTheme[ ]*=[ ]*.*;" => "\$this->sTheme= 'basic';" }
#   - htaccess_extra_replacements Extra replacements for htaccess
#   - db_setup_sql          The setup file to execute. By default "setup/sql/database.sql"
#   - extra_db_setup_sqls     Extra setup files to execute. e.g. ["setup/sql/demodata.sql"] will also install demo data. For
#   Ordering use Oxid::Mysql::ExecFile["source1"] -> Oxid::Mysql::ExecFile["source2"]
#   - owner             The owner of the directories
#   - group             The group of the directories
#
# Actions:
#   - Download and install oxid
#   - Create/drop and setups database
#   - Confugure config.inc.php and .htaccess
#   - Check File permission, owner and group
#   - update views
#
# Requires:
#   - Repository
#   - Apache instance
#   - MySQL Server instance
#   - PHP
#
# Sample Usage:
#    class { oxid:
#    source              => "OXID_ESHOP_EE_4.4.8_34028_for_PHP5.3.zip",
#    repository          => "oxidee",
#    shop_dir            => "/srv/www/oxid",
#    compile_dir         => "/srv/www/oxid/tmp",
#    db_host             => "localhost",
#    db_name             => "oxid",
#    db_user             => "oxid",
#    db_password         => "secret",
#    shop_ssl_url        => "https://myhostname",
#    admin_ssl_url       => "https://myhostname/admin",
#    mysql_user          => "root",
#    mysql_password      => "secret"
#  }
class oxid (
  $source,
  $repository          = $::oxid::params::default_repository,
  $shop_dir            = $::oxid::params::shop_dir,
  $compile_dir         = $::oxid::params::compile_dir,
  $db_type             = $::oxid::params::db_type,
  $db_host             = $::oxid::params::db_host,
  $db_name             = $::oxid::params::db_name,
  $db_user             = $::oxid::params::db_user,
  $db_password         = $::oxid::params::db_password,
  $shop_url            = $::oxid::params::shop_url,
  $shop_ssl_url        = $::oxid::params::shop_ssl_url,
  $admin_ssl_url       = $::oxid::params::admin_ssl_url,
  $utf8_mode           = $::oxid::params::utf8_mode,
  $mysql_user          = $::oxid::params::mysql_user,
  $mysql_password      = $::oxid::params::mysql_password,
  $rewrite_base        = $::oxid::params::rewrite_base,
  $config_content      = undef,
  $htaccess_content    = undef,
  $config_source       = undef,
  $htaccess_source     = undef,
  $config_extra_replacements   = {
  }
  ,
  $htaccess_extra_replacements = {
  }
  ,
  $db_setup_sql        = "setup/sql/database.sql",
  $extra_db_setup_sqls = undef,
  $owner               = $apache::params::user,
  $group               = $apache::params::group,
  $purge               = true,
  $sql_charset         = $oxid::params::default_charset) inherits ::oxid::params {
  include 'stdlib'
  include ::oxid::apache::params
  include oxid::mysql::params

  Oxid::Repository::Config::File <| |> -> Class[oxid]
  Oxid::Repository::Config::Wget <| |> -> Class[oxid]
  Class[oxid] -> Oxid::Theme<| |>
  Class[oxid] -> Oxid::Module<| |>
  
  if defined(Class['mysql::server']) {
    Class['mysql::server'] -> Oxid::Mysql::Dropdb["${name}: drop database"]
  }

  if defined(Package['mysql_client']) {
    Package['mysql_client'] -> Oxid::Mysql::Dropdb["${name}: drop database"]
  }

  if defined(Class['::apache']) {
    Exec["${name}: make dir ${shop_dir}"] -> Class['::apache']
  }

  if defined(Apache::Vhost) {
    Exec["${name}: make dir ${shop_dir}"] -> Apache::Vhost <| |>
  }

  oxid::fileCheck { $name:
    shop_dir    => $shop_dir,
    compile_dir => $compile_dir,
    owner       => $owner,
    group       => $group,
    refreshonly => true
  }

  oxid::updateViews { $name:
    shop_dir    => $shop_dir,
    refreshonly => true,
    require     => Oxid::FileCheck[$name]
  }

  if $purge {
    exec { "${name}: remove ${shop_dir}":
      command => "rm -r -f '${shop_dir}'",
      path    => $oxid::params::path,
      onlyif  => "test -d '${shop_dir}'",
      before  => Exec["${name}: make dir ${shop_dir}"]
    }
  }

  exec { "${name}: make dir ${shop_dir}":
    command => "mkdir -p ${shop_dir}",
    path    => $oxid::params::path,
    creates => $shop_dir,
    unless  => "test -d '${shop_dir}'"
  } ->
  oxid::repository::get { "${name}: get ${source}":
    repository => $repository,
    source     => $source
  } ->
  oxid::repository::unpack { "${name}: ${source}":
    repository  => $repository,
    source      => $source,
    destination => $shop_dir
  } ->
  oxid::mysql::dropdb { "${name}: drop database":
    host     => $db_host,
    db       => $db_name,
    user     => $mysql_user ? {
      undef   => $db_user,
      default => $mysql_user
    },
    password => $mysql_password ? {
      undef   => $db_password,
      default => $mysql_password
    }
  } ->
  oxid::mysql::createdb { "${name}: create database ${db_name}":
    host     => $db_host,
    db       => $db_name,
    user     => $mysql_user ? {
      undef   => $db_user,
      default => $mysql_user
    },
    password => $mysql_password ? {
      undef   => $db_password,
      default => $mysql_password
    },
    charset  => $utf8_mode ? {
      1       => 'utf8',
      default => 'latin1'
    }
  } ->
  oxid::mysql::grantdb { "${name}: grant database ${db_name}":
    host           => $db_host,
    db             => $db_name,
    user           => $mysql_user ? {
      undef   => $db_user,
      default => $mysql_user
    },
    password       => $mysql_password ? {
      undef   => $db_password,
      default => $mysql_password
    },
    grant_user     => $db_user,
    grant_password => $db_password
  } ->
  oxid::mysql::execFile { "${name}: init database ${db_name}":
    source   => $db_setup_sql,
    host     => $db_host,
    db       => $db_name,
    user     => $db_user,
    password => $db_password,
    cwd      => $shop_dir,
    charset  => $sql_charset
  } ->
  oxid::htaccess { $name:
    shop_dir           => $shop_dir,
    source             => $htaccess_source,
    content            => $htaccess_content,
    rewrite_base       => $rewrite_base,
    extra_replacements => $htaccess_extra_replacements
  } ->
  oxid::conf { $name:
    shop_dir           => $shop_dir,
    compile_dir        => $compile_dir,
    source             => $config_content,
    content            => $config_content,
    db_type            => $db_type,
    db_host            => $db_host,
    db_name            => $db_name,
    db_user            => $db_user,
    db_password        => $db_password,
    shop_url           => $shop_url,
    shop_ssl_url       => $shop_ssl_url,
    admin_ssl_url      => $admin_ssl_url,
    utf8_mode          => $utf8_mode,
    extra_replacements => $config_extra_replacements,
    notify             => Oxid::UpdateViews[$name]
  }

  if $extra_db_setup_sqls != undef {
    oxid::mysql::execFile { $extra_db_setup_sqls:
      host     => $db_host,
      db       => $db_name,
      user     => $db_user,
      password => $db_password,
      cwd      => $shop_dir,
      charset  => $sql_charset,
      require  => Oxid::Mysql::ExecFile["${name}: init database ${db_name}"],
      notify   => Oxid::UpdateViews[$name]
    }
  }
}
/* if $config_content != undef or $config_source != undef {
 * file { "${shop_dir}/config.inc.php":
 * ensure  => 'present',
 * mode    => "0400",
 * owner   => $owner,
 * group   => $group,
 * content => $config_content,
 * source  => $config_source,
 * require => Oxid::Repository::Get["${name} get source"],
 * notify  => Oxid::FileCheck[$name]
 *}
 * } else {
 * oxid::configureConfig { $name:
 * dbType       => $db_type,
 * dbHost       => $db_host,
 * dbName       => $db_name,
 * dbUser       => $db_user,
 * dbPwd        => $db_password,
 * sShopURL     => $shop_url,
 * sSSLShopURL  => $shop_sslUrl,
 * sAdminSSLURL => $shop_adminSslUrl,
 * sShopDir     => $shop_dir,
 * sCompileDir  => $compile_dir,
 * iUtfMode     => $utf8Mode,
 * require      => Oxid::Repository::Get["${name} get source"],
 * notify       => Oxid::FileCheck[$name]
 *}
 *}
 */

/* if $htaccess_content != undef or $htaccess_source != undef {
 * file { "${shop_dir}/.htaccess":
 * ensure  => 'present',
 * mode    => "0400",
 * owner   => $owner,
 * group   => $group,
 * content => $htaccess_content,
 * source  => $htaccess_source,
 * require => Oxid::Repository::Get["${name} get source"],
 * notify  => Oxid::FileCheck[$name]
 *}
 * } else {
 * oxid::configureHtaccess { $name:
 * sShopDir    => $shop_dir,
 * rewriteBase => $rewrite_path,
 * require     => Oxid::Repository::Get["${name} get source"],
 * notify      => Oxid::FileCheck[$name]
 *}
 *}
 *
 * if $extra_db_setup_sqls != undef {
 * oxid::mysql::execFile { $extra_db_setup_sqls:
 * host     => $db_host,
 * db       => $db_name,
 * user     => $db_user,
 * password => $db_password,
 * cwd      => $shop_dir,
 * charset  => $sql_charset,
 * require  => Oxid::Mysql::ExecFile[$db_setup_sql],
 * notify   => [Oxid::FileCheck[$name], Oxid::UpdateViews[$name]]
 *}
 *}
 */

/* define importData ($dest_dir, $tmp_dir = undef, $options = undef, $timeout = 18000, $unless = undef) {
 * case $name {
 * /^(https*:)(\/\/)*(.*\.tar\.gz|.*\.zip|.*\.gz|.*\.phar)$/ : {
 *   if $tmp_dir != undef {
 *     $real_tmp_Dir = $tmp_dir
 *   } else {
 *     $real_tmp_Dir = inline_template('<%= Dir.mktmpdir %>')
 *   }
 *
 *   $filename = "$3"
 *   $basename = inline_template('<%= File.basename(@filename) %>')
 *
 *   $real_output_file = "${real_tmp_Dir}/${basename}"
 *
 *   exec { "wget ${name}":
 *     command => "wget ${name} -O ${real_output_file}",
 *     path    => $oxid::params::path,
 *     unless  => $unless,
 *     timeout => $timeout
 *   } ->
 *   unpack { $real_output_file:
 *     destPath => $dest_dir,
 *     timeout  => $timeout,
 *     require  => Exec["wget ${name}"],
 *     unless   => $unless
 *   }
 *
 *   if $tmp_dir == undef {
 *     exec { "${name}-remove-tmp-files":
 *       command => "rm -f -r ${real_tmp_Dir}",
 *       path    => $oxid::params::path,
 *       unless  => $unless,
 *       require => Unpack[$real_output_file]
 *     }
 *   }
 *}
 *
 * /^(scp:)(\/\/)*(.*:)(\/)?(.*)$/ : {
 *   if $name =~ /.*(\.tar\.gz|\.zip|\.gz|\.phar)$/ {
 *     $extra_options = []
 *
 *     $filename = "$5"
 *     $basename = inline_template('<%= File.basename(@filename) %>')
 *
 *     $real_output_dir = $tmp_dir ? {
 *       undef   => inline_template('<%= Dir.mktmpdir %>'),
 *       default => $tmp_dir
 *     }
 *     $real_output_file = "${real_output_dir}/${basename}"
 *   } else {
 *     $extra_options = ["-r"]
 *
 *     $real_output_file = $dest_dir
 *   }
 *
 *   $real_options = concat($extra_options, $options)
 *
 *   if $options != undef {
 *     $option_str = join($real_options, ' ')
 *   } else {
 *     $option_str = ""
 *   }
 *
 *   exec { "scp ${option_str} $3$4$5 ${real_output_file}":
 *     path    => $oxid::params::path,
 *     unless  => $unless,
 *     timeout => $timeout
 *   }
 *
 *   if $name =~ /.*(\.tar\.gz|\.zip|\.phar$)/ and $tmp_dir == undef {
 *     unpack { $real_output_file:
 *       destPath => $dest_dir,
 *       timeout  => $timeout,
 *       require  => Exec["scp ${name}"],
 *       unless   => $unless
 *     } ->
 *     exec { "${name}-remove-tmp-files":
 *       command => "rm -f -r ${tmp_dir}",
 *       unless  => $unless,
 *       path    => $oxid::params::path
 *     }
 *   }
 *}
 *
 * /^(file*:)(\/\/)*(.*\.tar\.gz|.*\.zip|.*\.gz|.*\.phar)$/  : {
 *   unpack { $3:
 *     destPath => $dest_dir,
 *     unless   => $unless,
 *     timeout  => $timeout
 *   }
 *}
 *
 * /^(file*:)(\/\/)*(.*)$/         : {
 *   exec { "cp -f -r $3 $dest_dir":
 *     unless => $unless,
 *     path   => $oxid::params::path
 *   }
 *}
 * default : {
 *   fail("${name} not recordnized.")
 *}
 *}
 *}
 *
 * define importSQL (
 * $dest           = undev,
 * $host           = "localhost",
 * $db             = $oxid::params::db_name,
 * $mysql_user     = $oxid::params::db_user,
 * $mysql_password = $oxid::params::db_password,
 * $options        = undef,
 * $dump_options   = "--single-transaction --add-drop-table --allow-keywords --skip-extended-insert --hex-blob",
 * $dump_tables    = '',
 * $unless         = undef) {
 * case $name {
 * /^(https*|scp|file):(\/\/)*(.*\.tar\.gz|.*\.zip|.*\.gz|.*\.phar)$/ : {
 *   $tmp_dir = $dest ? {
 *     undef   => inline_template('<%= Dir.mktmpdir %>'),
 *     default => $dest
 *   }
 *
 *   importData { $name:
 *     dest_dir => $tmp_dir,
 *     tmp_dir  => $tmp_dir,
 *     options  => $options,
 *     unless   => $unless
 *   } ->
 *   exec { "mysql import file ${name}":
 *     command => "sh -c 'for file in ${tmp_dir}/*.sql; do mysql --host='${host}'
 *     --user='${mysql_user}' --password='${mysql_password}' '${db}' < \$file ; done'",
 *     unless  => $unless,
 *     path    => $oxid::params::path
 *   } ->
 *   exec { "${name}-remove-sql-tmp-files":
 *     command => "rm -f -r ${tmp_dir}",
 *     unless  => $unless,
 *     path    => $oxid::params::path
 *   }
 *}
 *
 * /^ssh:\/\/(.*):mysql:\/\/(.*)\/(.*)\?username=(.*)&password=(.*)/  : {
 *   if $options != undef {
 *     $option_str = join($options, ' ')
 *   } else {
 *     $option_str = ""
 *   }
 *
 *   $tmp_dir = inline_template('<%= Dir.mktmpdir %>')
 *   $remote_command = "mysqldump --host='$2' --user='$4' --password='$5' $dump_options '$3' $dump_tables"
 *
 *   $command = "ssh ${option_str} '$1' bash -s -- < $tmp_dir/remotecommand.sh | mysql --host='${host}' --user='${mysql_user}'
 *   --password='${mysql_password}' --database='${db}'"
 *
 *   file { "$tmp_dir": mode => 0777 } ->
 *   file { "$tmp_dir/remotecommand.sh":
 *     mode    => 0777,
 *     content => $remote_command
 *   } ->
 *   exec { $command:
 *     path   => $oxid::params::path,
 *     unless => $unless
 *   }
 *}
 *
 * /^(file):(\/\/)*(.*\.sql)$/ : {
 *   exec { "mysql import file $3":
 *     command => "mysql --host='${host}' --user='${mysql_user}' --password='${mysql_password}' '${db}' < $3",
 *     unless  => $unless,
 *     path    => $oxid::params::path
 *   }
 *}
 *
 * /(.*\.sql)$/                : {
 *   exec { "mysql import file $1":
 *     command => "mysql --host='${host}' --user='${mysql_user}' --password='${mysql_password}' ${db} < $1",
 *     unless  => $unless,
 *     path    => $oxid::params::path
 *   }
 *}
 *
 * default                     : {
 *   fail("${name} not recordnized.")
 *}
 *}
 *}
 */

/* define install_package (
 * $shop_dir,
 * $sql_scripts = undef,
 * $ensure      = "active",
 * $host        = "localhost",
 * $port        = $oxid::params::db_port,
 * $db          = $oxid::params::db_name,
 * $user        = $oxid::params::db_user,
 * $password    = $oxid::params::db_password) {
 * $tmp_dir = inline_template('<%= Dir.mktmpdir %>')
 *
 * unpack { $name: destPath => $tmp_dir }
 *
 * $exist = inline_template('<%= File.exists?(File.join(@tmp_dir, "copy_this")) %>')
 *
 * if ($exist == "true") {
 * exec { "cp -R -f ${tmp_dir}/copy_this/* ${shop_dir}":
 *   path    => $oxid::params::path,
 *   before  => Exec["rm -r -f ${tmp_dir}"],
 *   require => Unpack[$name]
 *}
 * } else {
 * exec { "cp -R -f ${tmp_dir}/* ${shop_dir}":
 *   path    => $oxid::params::path,
 *   before  => Exec["rm -r -f ${tmp_dir}"],
 *   require => Unpack[$name]
 *}
 *}
 *
 * if($sql_scripts != undef) {
         $sql_files = split(inline_template("<%= @sql_scripts.each {|f| File.join(@tmp_dir, f)
 * }.join(',') %>"), ',')
         
         oxid::mysql::server::execFile{$sql_files:       
            host => $host,
 * port => $port,
            db => $db,
            user => $user, 
            password => $password,
            before =>
 * Exec["rm -r -f * ${tmp_dir}"]
        }
    }
 *
 * exec { "rm -r -f ${tmp_dir}": path => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin" }
 *}
 */


/* class oxid::lastcheck($configurations, $owner = "www-data", $group = "www-data") {
    $module_path = get_module_path('oxid')
 * $shop_dir = $configurations['sShopDir']
    $compile_dir = $configurations['sCompileDir']
    $url = $configurations['sShopURL']
 * $admin_url = $configurations['sAdminSSLURL'] ? { 
        undef =>
 * "${url}/admin", 
        default => $configurations['sAdminSSLURL']
    }
    
    exec { "oxid-check-owner
 * ${shop_dir}": 
      command => "chown -R ${owner}:${group} '${shop_dir}' & chmod -R ug+rw
 * '${shop_dir}'", 
      path => $oxid::params::path
    } ->
    
    exec { "oxid-check-owner ${compile_dir}":
 * command => "chown -R ${owner}:${group} '${compile_dir}' & chmod -R ug+rw '${compile_dir}'", 
      path =>
 * $oxid::params::path
    } ->
    
    file {
 * "${shop_dir}/tmp":
      ensure => 'present',
      mode => "ug+rw"
    } -> 

    file { "${shop_dir}/setup":
      ensure =>
 * 'absent',
      force => true
    } ->
    
    file {
 * "${shop_dir}/updateApp":
      ensure => 'absent',
      force => true
    } ->
    
    exec { "rm -r -f ${compile_dir}/*":
 * path   => $oxid::params::path
    } ->
    
    file {
 * "${shop_dir}/start_updateviews.php":
            ensure => 'present',
            mode => "0755",
            owner => $owner,
 * group => $group,
            source => "$module_path/files/oxid/updateviews-all.php"
    } ->
    
    exec
 * {"oxid-check-admin-url-${shop_dir}":
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        command => "wget --spider --no-check-certificate ${admin_url}"
 * } ->
    
    exec
 * {"oxid-check-shop-url-${shop_dir}":
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        command => "wget --spider --no-check-certificate ${$url}"
    } ->
    

    exec {"oxid-updateviews-${shop_dir}":
 * path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        command => "wget --spider --no-check-certificate
 * ${$url}/start_updateviews.php"
    } ->
    
    exec
 * {"oxid-updateviews-${shop_dir}2":
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        command => "wget --spider --no-check-certificate ${$url}/start_updateviews.php"
    } ->
    
    exec {"oxid-updateviews-${shop_dir}3":
 * path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        command => "wget --spider --no-check-certificate
 * ${$url}/start_updateviews.php"
    } ->
    
    exec { "rm -f ${shop_dir}/start_updateviews.php":
        path   =>
 * $oxid::params::path
    }    
}
 */