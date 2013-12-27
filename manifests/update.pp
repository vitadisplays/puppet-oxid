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
  $owner            = $apache::params::user,
  $group            = $apache::params::group,
  $source           = undef,
  $repository       = $oxid::params::default_repository,
  $copy_this        = 'before',
  $changed_full     = 'after',
  $run_method       = "cli",
  $answers          = [],
  $fail_on_error    = true,
  $updateViews      = true,
  $timeout          = 900) {
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

  $cmds = [
    "cp -R -f ${oxid::params::tmp_dir}/${filename}/updateApp/ ${shop_dir}/",
    "cp -R -f ${oxid::params::tmp_dir}/${filename}/copy_this/* ${shop_dir}/",
    "cp -R -f ${oxid::params::tmp_dir}/${filename}/changed_full/* ${shop_dir}/",
    "rm -r -f '${oxid::params::tmp_dir}/${filename}'"]

  oxid::fileCheck { $name:
    shop_dir    => $shop_dir,
    compile_dir => $compile_dir,
    owner       => $owner,
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
    destination => "${oxid::params::tmp_dir}/${filename}"
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

  exec { $cmds[0]:
    path    => $oxid::params::path,
    onlyif  => "test -d '${oxid::params::tmp_dir}/${filename}/updateApp'",
    timeout => 120,
    notify  => [Oxid::FileCheck[$name], Exec[$cmds[3]]],
    require => Oxid::Repository::Unpack["${name}: ${mysource}"]
  }

  if $copy_this == 'before' or $copy_this == 'after' {
    exec { $cmds[1]:
      path    => $oxid::params::path,
      onlyif  => "test -d '${oxid::params::tmp_dir}/${filename}/copy_this'",
      timeout => 120,
      before  => [Oxid::Conf[$name], Oxid::Htaccess[$name]],
      require => Oxid::Repository::Unpack["${name}: ${mysource}"],
      notify  => [Oxid::FileCheck[$name], Exec[$cmds[3]]]
    }
  }

  if $changed_full == 'before' or $changed_full == 'after' {
    exec { $cmds[2]:
      path    => $oxid::params::path,
      onlyif  => "test -d '${oxid::params::tmp_dir}/${filename}/changed_full'",
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

      file { $php_file:
        content => template("oxid/oxid/updateApp/run_unattended_cli.php.erb"),
        require => Exec[$cmds[0]]
      } ->
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
      $sql_dir = inline_template("<%= File.join(@shop_dir, 'updateApp', 'updates', 'sql') %>")

      oxid::mysql::execDirectory { "${name}: update database from ${sql_dir}":
        directory => $sql_dir,
        pattern   => "*.sql",
        host      => $db_host,
        db        => $db_name,
        user      => $db_user,
        password  => $db_password
      }

      case $copy_this {
        'before' : { Exec[$cmds[0]] -> Exec[$cmds[1]] -> Oxid::Mysql::ExecDirectory["${name}: update database from ${sql_dir}"] }
        'after'  : { Exec[$cmds[0]] -> Oxid::Mysql::ExecDirectory["${name}: update database from ${sql_dir}"] -> Exec[$cmds[1]] }
        default  : { Exec[$cmds[0]] -> Oxid::Mysql::ExecDirectory["${name}: update database from ${sql_dir}"] }
      }

      case $changed_full {
        'before' : { Exec[$cmds[0]] -> Exec[$cmds[2]] -> Oxid::Mysql::ExecDirectory["${name}: update database from ${sql_dir}"] }
        'after'  : { Exec[$cmds[0]] -> Oxid::Mysql::ExecDirectory["${name}: update database from ${sql_dir}"] -> Exec[$cmds[2]] }
        default  : { Exec[$cmds[0]] -> Oxid::Mysql::ExecDirectory["${name}: update database from ${sql_dir}"] }
      }

      if $updateViews {
        oxid::updateViews { $name:
          shop_dir    => $shop_dir,
          refreshonly => false,
          notify      => Oxid::FileCheck[$name],
          require     => Oxid::Mysql::ExecDirectory["${name}: update database from ${sql_dir}"]
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
