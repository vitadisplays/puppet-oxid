import "conf.pp"
import "utils.pp"
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
  $source_password     = undef,
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
  $purge               = false,
  $sql_charset         = $oxid::params::default_charset) inherits ::oxid::params {
  include 'stdlib'
  include ::oxid::apache::params
  include oxid::mysql::params

  Oxid::Repository::Config::File <| |> -> Class[oxid]
  Oxid::Repository::Config::Wget <| |> -> Class[oxid]
  Class[oxid] -> Oxid::Theme <| |>
  Class[oxid] -> Oxid::Module <| |>

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
    destination => $shop_dir,
    password    => $source_password
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