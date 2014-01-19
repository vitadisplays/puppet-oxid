define oxid::shopConfigS (
  $shopid   = $oxid::params::default_shopid,
  $configs,
  $host     = $oxid::params::db_host,
  $port     = $oxid::params::db_port,
  $db       = $oxid::params::db_name,
  $user     = $oxid::params::db_user,
  $password = $oxid::params::db_password) {
  $_req = defined(Class[oxid]) ? {
    true    => Class[oxid],
    default => undef
  }

  $value = $configs[$name]
  $query = "UPDATE oxshops SET ${name}='${value}' WHERE oxid = '${shopid}'"

  oxid::mysql::execSQL { "${name}: ${query}":
    query    => $query,
    host     => $host,
    db       => $db,
    port     => $port,
    user     => $user,
    password => $password,
    require  => $_req
  }
}

# Define: oxid::shopConfig
#
# This define sets new values to oxshop table.
#
# Parameters:
#
# - shopid      Shop id of the shop to set new values. Default is 'oxbaseshop'. On EE Version always define this parameter.
# - configs     Hash with Key/Value Pairs, e.g. { 'columname' => 'new value' }
# - host        Database host: Default is "localhost".
# - port        Database port: Default is 3306.
# - db          Database name: Default is "oxid".
# - user        Database user: Default is "oxid".
# - password    Database password: Default is "oxid".
#
# Actions:
#   - Download and install theme
#   - activate theme
#   - Configure theme
#   - Check File permission, owner and group
#
# Requires:
#   - Repository
#   - Apache instance
#   - MySQL Server instance
#   - PHP
#   - Configured oxid shop
#
# Sample Usage:
#   oxid::shopConfig{'oxidee':
#      shopid  => 1,
#      host => "localhost",
#      port => 3306,
#      db => "oxid",
#      user => "oxid",
#      password => "",
#      configs => {
#         "oxtitleprefix" => "",
#         "oxtitlesuffix" => "My New SHOP",
#         "oxinfoemail" => "info@example.com",
#         "oxorderemail" => "info@example.com",
#         "oxowneremail" => "info@example.com",
#      }
#   }
define oxid::shopConfig (
  $shopid   = 'oxbaseshop',
  $configs,
  $host     = $oxid::params::db_host,
  $port     = $oxid::params::db_port,
  $db       = $oxid::params::db_name,
  $user     = $oxid::params::db_user,
  $password = $oxid::params::db_password) {
  $configKeys = keys($configs)

  oxid::shopConfigS { $configKeys:
    shopid   => $shopid,
    configs  => $configs,
    host     => $host,
    port     => $port,
    db       => $db,
    user     => $user,
    password => $password
  }
}