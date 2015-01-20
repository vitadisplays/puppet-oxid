include 'stdlib'
include ::oxid::params

import "conf.pp"
import "utils.pp"
import "updateViews.pp"
import "remoteUtils.pp"
import "php/zendguardloader.pp"

# Class: oxid
#
# This class installs Oxid.
#
# This class use the orginal config.inc.php and .htaccess provided by the source archive and configure the files by replacing
# elements.
# This allows you to configure all version of the config.inc.php and .htaccess provided by oxid.
# If you don't need this feature, yo can define your own config.inc.php and .htaccess source.
#
# Parameters:
#
#   - source                    The location of the setup archive in the defined repository. Required.
#   - repository                The repository to get from. Default is local file use.
#   - purge                     If true, deletes the shop dir and all tables/views in database. Default is true.
#   - shop_dir                  The oxid shop directroy. Default is "/srv/www/oxid"
#   - compile_dir               The oxid compile directroy. Default is "/srv/www/oxid/tmp"
#   - db_type                   Default is mysql and is the only supported type.
#   - db_host                   Oxid database host. Default "localhost".
#   - db_port                   Oxid database port. Default 3306.
#   - db_name                   Oxid database name. Default "oxid".
#   - db_user                   Oxid database user. Default "oxid".
#   - db_password               Oxid database password. Required.
#   - shop_url                  Oxid shop url. Default "http://${hostname}"
#   - shop_ssl_url              Oxid shop ssl url. Default is undef.
#   - admin_ssl_url             Oxid admin ssl url. Default is undef.
#   - utf8_mode                 Oxid UTF8 Mode. 0 for latin1 and 1 for UTF8. Default is 0.
#   - rewrite_base              Rewrite Base in the .htaccess file. Default is "/"
#   - config_content            Your own oxyid configuration content. Default is undef.
#   - htaccess_content          Your own htaccess configuration content. Default is undef.
#   - config_source             Your own oxid configuration source. Default is undef.
#   - htaccess_source           Your own oxid htaccess source. Default is undef.
#   - config_extra_replacements   Extra replacements for oxid configuration. Example:
#   {"\$this->sTheme[ ]*=[ ]*.*;" => "\$this->sTheme= 'basic';" }. Default is undef.
#   - htaccess_extra_replacements Extra replacements for htaccess. Default is undef.
#   - db_setup_sqls             The setup file to execute. Default is ["setup/sql/database.sql"]. Use ["setup/sql/database.sql", "setup/sql/demodata.sql"] to install also demodata. Ordering will be recordnized.
#   Ordering use Oxid::Mysql::ExecFile["source1"] -> Oxid::Mysql::ExecFile["source2"]. Default is undef.
#   - owner                     The owner of the directories. Default see $apache::params::user.
#   - group                     The group of the directories. Default see $apache::params::group.
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
#   oxid::repository::config::wget{ "oxidce": url => "http://download.oxid-esales.com/ce" }
#
#   class { oxid:
#     source              => { "index.php" => "OXID_ESHOP_CE_CURRENT.zip" },
#     repository          => "oxidce",
#     shop_dir            => "/srv/www/oxid",
#     compile_dir         => "/srv/www/oxid/tmp",
#     db_host             => "localhost",
#     db_name             => "oxid",
#     db_user             => "oxid",
#     db_password         => "secret",
#     shop_ssl_url        => "https://myhostname",
#     admin_ssl_url       => "https://myhostname/admin"
#   }
#
#   Creates a wget remote repository to the oxid community download location and installs an oxid community edition shop server with
#   demodata.
#   MySQL, Apache and PHP installation are hidden. See the corresponding documentation how to install them.
#
class oxid (
  $source,
  $repository          = $::oxid::params::default_repository,
  $source_password     = undef,
  $shop_dir            = $::oxid::params::shop_dir,
  $compile_dir         = $::oxid::params::compile_dir,
  $db_type             = $::oxid::params::db_type,
  $db_host             = $::oxid::params::db_host,
  $db_port             = $::oxid::params::db_port,
  $db_name             = $::oxid::params::db_name,
  $db_user             = $::oxid::params::db_user,
  $db_password,
  $shop_url            = $::oxid::params::shop_url,
  $shop_ssl_url        = $::oxid::params::shop_ssl_url,
  $admin_ssl_url       = $::oxid::params::admin_ssl_url,
  $utf8_mode           = $::oxid::params::utf8_mode,
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
  $db_setup_sqls       = ["setup/sql/database.sql"],
  $extra_db_setup_sqls = undef,
  $owner               = $apache::params::user,
  $group               = $apache::params::group,
  $purge               = true) {

  validate_array($db_setup_sqls)

  Oxid::Repository::Config::File <| |> -> Oxid::Repository::Config::Wget <| |> -> Class[oxid]

  Class[oxid] -> Oxid::Theme <| |> -> Oxid::Module <| |>

  if defined(Class['mysql::server']) {
    Class['mysql::server'] -> Class[oxid]
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  if defined(Package['mysql_client']) {
    Package['mysql_client'] -> Class[oxid]
  }

  if defined(Class['::apache']) {
    Exec["${name}: make dir ${shop_dir}"] -> Class['::apache']
  }

  if defined(Apache::Vhost) {
    Exec["${name}: make dir ${shop_dir}"] -> Apache::Vhost <| |>
  }

  if defined(Service['httpd']) {
    Class[oxid] ~> Service['httpd']
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

    mysql_tables { $name:
      command     => "drop",
      db_host     => $db_host,
      db_port     => $db_port,
      db_user     => $db_user,
      db_password => $db_password,
      db_name     => $db_name,
      before      => Mysql_import[$db_setup_sqls]
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
  /* oxid::mysql::initdb { "${name}: init database ${db_name}":
   * host           => $db_host,
   * db             => $db_name,
   * user           => $mysql_user ? {
   * undef   => $db_user,
   * default => $mysql_user
   * },
   * password       => $mysql_password ? {
   * undef   => $db_password,
   * default => $mysql_password
   * },
   * charset        => $utf8_mode ? {
   * 1       => 'utf8',
   * default => 'latin1'
   * },
   * collation      => $utf8_mode ? {
   * 1       => 'utf8_general_ci',
   * default => 'latin1_general_ci'
   * },
   * grant_user     => $db_user,
   * grant_password => $db_password
   * } ->
   */
  mysql_import { $db_setup_sqls:
    db_host     => $db_host,
    db_port     => $db_port,
    db_user     => $db_user,
    db_password => $db_password,
    db_name     => $db_name,
    cwd         => $shop_dir,
    require     => Class[::mysql::client]
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
}