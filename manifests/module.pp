define oxid::module (
  $shopid     = $oxid::params::default_shopid,
  $modules    = undef,
  $ensure     = "present",
  $host       = $oxid::params::db_host,
  $port       = $oxid::params::db_port,
  $db         = $oxid::params::db_name,
  $user       = $oxid::params::db_user,
  $password   = $oxid::params::db_password,
  $config_key = $oxid::params::config_key) {
  $module_path = get_module_path('oxid')

  if $ensure == 'absent' {
    if (is_array($modules) or (is_string($modules)) and $modules != "*") {
      $jsonHash = {
        'command'  => "delete",
        'module'   => $modules,
        'shopid'   => $shopid,
        'host'     => "${host}:${port}",
        'db'       => $db,
        'user'     => $user,
        'password' => $password
      }
    } elsif is_string($modules) and $modules == "*" {
      $jsonHash = {
        'command'  => "clear",
        'shopid'   => $shopid,
        'host'     => "${host}:${port}",
        'db'       => $db,
        'user'     => $user,
        'password' => $password
      }
    } else {
      err("Modules for delete command should be a array or string.")
    }
  } elsif $ensure == "present" {
    $jsonHash = {
      'command'   => "add",
      'module'    => $modules,
      'shopid'    => $shopid,
      'host'      => "${host}:${port}",
      'db'        => $db,
      'user'      => $user,
      'password'  => $password,
      'configkey' => $config_key
    }
  } elsif $ensure == "override" {
    $jsonHash = {
      'command'   => "set",
      'module'    => $modules,
      'shopid'    => $shopid,
      'host'      => "${host}:${port}",
      'db'        => $db,
      'user'      => $user,
      'password'  => $password,
      'configkey' => $config_key
    }
  } else {
    err("Module ensure should be present, absent or override")
  }

  $cmd = inline_template('<%= require "json"; JSON.generate @jsonHash %>')

  oxid::php::runner { "${name}: oxid-module ${cmd}":
    source  => "${module_path}/functions/oxid/oxid-modules.php",
    options => ["'${cmd}'"]
  }
}