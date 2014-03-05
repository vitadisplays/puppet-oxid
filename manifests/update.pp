import "conf.pp"
import "utils.pp"
import "updateViews.pp"

# Define: oxid::update
#
# This define update an existing Oxid instance.
#
# This define use the orginal config.inc.php and .htaccess if provided by the source archive and configure the files by replacing
# elements.
# This allows you to configure all version of the config.inc.php and .htaccess provided by oxid.
# If you don't need this feature, you can define your own config.inc.php and .htaccess source.
#
# The update Procces is default done by the run_cli.php script. This script will be extended that uses unanttended UI Classes.
# Over the Answer parameter, you can define your Answers like ["1", "2", "1"]. Return Answers are handled by default.
# Sometimes the run_cli.php script do not handle the SQL scripts well. In this case, use run_method => "sql", to run only the SQL
# Scripts directly by mysql.
#
# Parameters:
#   - source                        The location of the setup archive in the defined repository. Required.
#   - repository                    The repository to get from. Default is local file use.
#   - shop_dir                      The oxid shop directroy. Default is "/srv/www/oxid"
#   - compile_dir                   The oxid compile directroy. Default is "/srv/www/oxid/tmp"
#   - db_type                       Default is mysql and is the only supported type.
#   - db_host                       Oxid database host. Default "localhost".
#   - db_name                       Oxid database name. Default "oxid".
#   - db_user                       Oxid database user. Default "oxid".
#   - db_password                   Oxid database password. Default "oxid".
#   - shop_url                      Oxid shop url. Default "http://${hostname}"
#   - shop_ssl_url                  Oxid shop ssl url. Default is undef.
#   - admin_ssl_url                 Oxid admin ssl url. Default is undef.
#   - utf8_mode                     Oxid UTF8 Mode. 0 for latin1 and 1 for UTF8. Default is 0.
#   - rewrite_base                  Rewrite Base in the .htaccess file. Default is "/"
#   - config_content                Your own oxyid configuration content. Default is undef.
#   - htaccess_content              Your own htaccess configuration content. Default is undef.
#   - config_source                 Your own oxid configuration source. Default is undef.
#   - htaccess_source               Your own oxid htaccess source. Default is undef.
#   - config_extra_replacements     Extra replacements for oxid configuration. Example:
#   {"\$this->sTheme[ ]*=[ ]*.*;" => "\$this->sTheme= 'basic';" }. Default is undef.
#   - htaccess_extra_replacements   Extra replacements for htaccess. Default is undef.
#   - db_setup_sql                  The setup file to execute. By default "setup/sql/database.sql". Default is undef.
#   - extra_db_setup_sqls           Extra setup files to execute. e.g. ["setup/sql/demodata.sql"] will also install demo data. For
#   Ordering use Oxid::Mysql::ExecFile["source1"] -> Oxid::Mysql::ExecFile["source2"]. Default is undef.
#   - owner                         The owner of the directories. Default see $apache::params::user.
#   - group                         The group of the directories. Default see $apache::params::group.
#   - copy_this                     before or after update process to copy all files from the copy_this directory to the shop
#   directory. Use none to stop copy.
#   - changed_full                  before or after update process to copy all files from the xhanged_full directory to the shop
#   directory. Use none to stop copy.
#   - run_method                    cli or sql. In the cli mode the run_cli.php will be executed and in sql mode only the sql files
#   will be executed. Default is "cli".
#   - answers                       Anwser array
#   - fail_on_error                 Some times some sql statments failed. to ignore this you can change the fail on error behaviour.
#   Default true.
#   - updateViews                   If true, update all views. Default true.
#   - timeout                       the timeout for the update process. Default 900.
#
# Actions:
#   - Download and install oxid update package
#   - Copy package content to shop directory
#   - run update process
#   - Check File permission, owner and group
#   - update views
#
# Requires:
#   - Repository
#   - Oxid instance
#
# Sample Usage:
#    oxid::update { $name:
#     shop_dir            => "/srv/www/oxid",
#     compile_dir         => "/srv/www/oxid/tmp",
#     db_host             => "localhost",
#     db_name             => "oxid",
#     db_user             => "oxid",
#     db_password         => "secret",
#     shop_ssl_url        => "https://myhostname",
#     admin_ssl_url       => "https://myhostname/admin",
#     source => "UPDATE_OXID_ESHOP_EE_V.4.4.8_34028_TO_V.4.6.5_49955_for_PHP5.3.zip",
#     repository => "oxidee",
#     answers => ["2", "1", "1"],
#     fail_on_error => true
#  }
define oxid::update (
  $shop_dir         = $oxid::params::shop_dir,
  $compile_dir      = $oxid::params::compile_dir,
  $db_type          = $oxid::params::db_type,
  $db_host          = $oxid::params::db_host,
  $db_name          = $oxid::params::db_name,
  $db_user          = $oxid::params::db_user,
  $db_password      = $oxid::params::db_password,
  $shop_url         = $oxid::params::shop_url,
  $shop_ssl_url     = $oxid::params::shop_ssl_url,
  $admin_ssl_url    = $oxid::params::admin_ssl_url,
  $utf8_mode        = $oxid::params::utf8_mode,
  $mysql_user       = $oxid::params::mysql_user,
  $mysql_password   = $oxid::params::mysql_password,
  $rewrite_base     = $oxid::params::rewrite_base,
  $config_content   = undef,
  $htaccess_content = undef,
  $config_source    = undef,
  $htaccess_source  = undef,
  $config_extra_replacements   = {
  }
  ,
  $htaccess_extra_replacements = {
  }
  ,
  $user             = $apache::params::user,
  $group            = $apache::params::group,
  $source           = undef,
  $repository       = $oxid::params::default_repository,
  $source_password  = undef,
  $copy_this        = 'before',
  $changed_full     = 'after',
  $run_method       = "cli",
  $answers          = [],
  $fail_on_error    = true,
  $updateViews      = true,
  $timeout          = 900) {
  include 'stdlib'
  include ::oxid::apache::params
  include oxid::mysql::params

  Oxid::Repository::Config::File <| |> -> Oxid::Repository::Config::Wget <| |> -> Oxid::Update <| |>

  if defined(Service['httpd']) {
    Oxid::Update[$name] ~> Service['httpd']
  }

  validate_re($copy_this, ['^before$', '^after$', '^never$'], "Only before, after or never for copy_this parameter are supported.")
  validate_re($changed_full, ['^before$', '^after$', '^never$'], "Only before, after or never for changed_full parameter are supported."
  )
  validate_re($run_method, ["^cli$", "^sql$"])
  validate_bool($fail_on_error, $updateViews)

  validate_array($answers)

  $mysource = $source ? {
    undef   => $name,
    default => $source
  }

  $filename = inline_template('<%= File.basename(@mysource) %>')
  $archive_dir = "${oxid::params::tmp_dir}/${filename}"

  $cmds = [
    "cp -R -f ${archive_dir}/updateApp/ ${shop_dir}/",
    "cp -R -f ${archive_dir}/copy_this/* ${shop_dir}/",
    "cp -R -f ${archive_dir}/changed_full/* ${shop_dir}/",
    "rm -r -f '${archive_dir}'"]

  oxid::fileCheck { $name:
    shop_dir    => $shop_dir,
    compile_dir => $compile_dir,
    owner       => $user,
    group       => $group,
    refreshonly => true
  }

  oxid::repository::get { "${name}: get ${mysource}":
    source     => $mysource,
    repository => $repository,
    notify     => Exec[$cmds[3]]
  } ->
  oxid::repository::unpack { "${name}: ${mysource}":
    repository  => $repository,
    source      => $mysource,
    destination => "${oxid::params::tmp_dir}/${filename}",
    password    => $source_password
  }

  exec { $cmds[3]:
    path        => $oxid::params::path,
    refreshonly => true,
    require     => Oxid::Repository::Unpack["${name}: ${mysource}"]
  }

  oxid::htaccess { $name:
    shop_dir           => $shop_dir,
    source             => $htaccess_source,
    content            => $htaccess_content,
    rewrite_base       => $rewrite_base,
    extra_replacements => $htaccess_extra_replacements,
    require            => Oxid::Repository::Unpack["${name}: ${mysource}"]
  }

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
    require            => Oxid::Repository::Unpack["${name}: ${mysource}"],
    notify             => Oxid::UpdateViews[$name]
  }

  if $copy_this == 'before' or $copy_this == 'after' {
    exec { $cmds[1]:
      path    => $oxid::params::path,
      onlyif  => "test -d '${archive_dir}/copy_this'",
      timeout => 120,
      before  => [Oxid::Conf[$name], Oxid::Htaccess[$name]],
      require => Oxid::Repository::Unpack["${name}: ${mysource}"],
      notify  => [Oxid::FileCheck[$name], Exec[$cmds[3]]]
    }
  }

  if $changed_full == 'before' or $changed_full == 'after' {
    exec { $cmds[2]:
      path    => $oxid::params::path,
      onlyif  => "test -d '${archive_dir}/changed_full'",
      timeout => 120,
      before  => [Oxid::Conf[$name], Oxid::Htaccess[$name]],
      require => Oxid::Repository::Unpack["${name}: ${mysource}"],
      notify  => [Oxid::FileCheck[$name], Exec[$cmds[3]]]
    }
  }

  case $run_method {
    'cli' : {
      $run_cli_filename = inline_template("<%= File.basename(@filename, '.*') %>")
      $php_file = "${shop_dir}/updateApp/${run_cli_filename}.php"

      exec { $cmds[0]:
        path    => $oxid::params::path,
        notify  => [Oxid::FileCheck[$name], Exec[$cmds[3]]],
        require => Oxid::Repository::Unpack["${name}: ${mysource}"]
      } ->
      file { $php_file: content => template("oxid/oxid/updateApp/run_unattended_cli.php.erb") } ->
      oxid::php::runner { "${name}: run cli ${php_file}":
        source  => $php_file,
        output  => "${shop_dir}/log/${run_cli_filename}.log",
        timeout => $timeout,
        notify  => Oxid::FileCheck[$name]
      }

      case $copy_this {
        'before' : { Exec[$cmds[0]] -> Exec[$cmds[1]] -> Oxid::Php::Runner["${name}: run cli ${php_file}"] }
        'after'  : { Exec[$cmds[0]] -> Oxid::Php::Runner["${name}: run cli ${php_file}"] -> Exec[$cmds[1]] }
        default  : { Exec[$cmds[0]] -> Oxid::Php::Runner["${name}: run cli ${php_file}"] }
      }

      case $changed_full {
        'before' : { Exec[$cmds[0]] -> Exec[$cmds[2]] -> Oxid::Php::Runner["${name}: run cli ${php_file}"] }
        'after'  : { Exec[$cmds[0]] -> Oxid::Php::Runner["${name}: run cli ${php_file}"] -> Exec[$cmds[2]] }
        default  : { Exec[$cmds[0]] -> Oxid::Php::Runner["${name}: run cli ${php_file}"] }
      }

      if $updateViews {
        oxid::updateViews { $name:
          shop_dir    => $shop_dir,
          refreshonly => false,
          notify      => Oxid::FileCheck[$name],
          require     => Oxid::Php::Runner["${name}: run cli ${php_file}"]
        }
      }
    }
    'sql' : {
      $sql_dir = inline_template("<%= File.join(@archive_dir, 'updateApp', 'updates', 'sql') %>")

      if !defined(Class[::mysql::client]) {
        include ::mysql::client
      }

      mysql_import { "${sql_dir}/*.sql":
        db_host     => $db_host,
        db_user     => $user,
        db_password => $db_password,
        db_name     => $db_name,
        require     => Class[::mysql::client]
      }

      /* oxid::mysql::execDirectory { "${name}: update database from ${sql_dir}":
       * directory => $sql_dir,
       * pattern   => "*.sql",
       * host      => $db_host,
       * db        => $db_name,
       * user      => $db_user,
       * password  => $db_password
       *}
       */

      case $copy_this {
        'before' : {
          Exec[$cmds[1]] -> Mysql_import ["${sql_dir}/*.sql"]
        }
        'after'  : {
          Mysql_import ["${sql_dir}/*.sql"] -> Exec[$cmds[1]]
        }
        default  : {
          Oxid::Repository::Unpack["${name}: ${mysource}"] -> Mysql_import ["${sql_dir}/*.sql"]
        }
      }

      case $changed_full {
        'before' : {
          Exec[$cmds[2]] -> Mysql_import ["${sql_dir}/*.sql"]
        }
        'after'  : {
          Mysql_import ["${sql_dir}/*.sql"] -> Exec[$cmds[2]]
        }
        default  : {
          Oxid::Repository::Unpack["${name}: ${mysource}"] -> Mysql_import ["${sql_dir}/*.sql"]
        }
      }

      if $updateViews {
        oxid::updateViews { $name:
          shop_dir    => $shop_dir,
          refreshonly => false,
          notify      => Oxid::FileCheck[$name],
          require     => Mysql_import["${sql_dir}/*.sql"]
        }
      }
    }
  }

  /* if $run_cli {
   * $run_cli_filename = inline_template("<%= File.basename(@filename, '.*') %>")
   * $php_file = "${shop_dir}/updateApp/${run_cli_filename}.php"
   *
   * file { $php_file:
   * content => template("oxid/oxid/updateApp/run_unattended_cli.php.erb"),
   * require => Exec[$cmds[0]]
   * } ->
   * exec { "${name}: run cli ${php_file}":
   * command => "php -f ${php_file} > ${shop_dir}/log/${run_cli_filename}.log",
   * path    => $oxid::params::path,
   * timeout => $timeout,
   * notify  => Oxid::FileCheck[$name]
   *}
   *
   * if $updateViews {
   * oxid::updateViews { $name:
   *   shop_dir    => $shop_dir,
   *   refreshonly => false,
   *   notify      => Oxid::FileCheck[$name],
   *   require     => Exec["${name}: run cli ${php_file}"]
   *}
   *}
   *}
   */

  /* $configs_req = unique([
   * Exec[$cmds[0]],
   * $run_cli ? {
   * true    => Exec["${name}: run cli ${php_file}"],
   * default => Exec[$cmds[0]]
   * },
   * $copy_this ? {
   * 'before' => Exec[$cmds[1]],
   * 'after'  => Exec[$cmds[1]],
   * default  => Exec[$cmds[0]]
   * },
   * $changed_full ? {
   * 'before' => Exec[$cmds[2]],
   * 'after'  => Exec[$cmds[2]],
   * default  => Exec[$cmds[0]]
   * } ])
   */


  /* if $config_content != undef or $config_source != undef {
   * file { "${shop_dir}/config.inc.php":
   * ensure  => 'present',
   * mode    => "0400",
   * owner   => $owner,
   * group   => $group,
   * content => $config_content,
   * source  => $config_source,
   * require => $configs_req,
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
   * require      => $configs_req,
   * notify       => Oxid::FileCheck[$name]
   *}
   *}
   *
   * if $htaccess_content != undef or $htaccess_source != undef {
   * file { "${shop_dir}/.htaccess":
   * ensure  => 'present',
   * mode    => "0400",
   * owner   => $owner,
   * group   => $group,
   * content => $htaccess_content,
   * source  => $htaccess_source,
   * require => $configs_req,
   * notify  => Oxid::FileCheck[$name]
   *}
   * } else {
   * oxid::configureHtaccess { $name:
   * sShopDir    => $shop_dir,
   * rewriteBase => $rewrite_path,
   * require     => $configs_req,
   * notify      => Oxid::FileCheck[$name]
   *}
   *}
   */
}
