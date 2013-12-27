define oxid::shopConfigSinleAction (
  $shopid   = $oxid::params::default_shopid,
  $configs,
  $host     = $oxid::params::db_host,
  $port     = $oxid::params::db_port,
  $db       = $oxid::params::db_name,
  $user     = $oxid::params::db_user,
  $password = $oxid::params::db_password) {
  $value = $configs[$name]
  $query = "UPDATE oxshops SET ${name}='${value}' WHERE oxid = '${shopid}'"

  exec { $query:
    command => "mysql -h ${host} -P ${port} -u${user} -p${password} ${db} -e \"${query}\"",
    path    => $oxid::params::path
  }
}

define oxid::shopConfig (
  $shopid   = $oxid::params::default_shopid,
  $configs,
  $host     = $oxid::params::db_host,
  $port     = $oxid::params::db_port,
  $db       = $oxid::params::db_name,
  $user     = $oxid::params::db_user,
  $password = $oxid::params::db_password) {
  $configKeys = keys($configs)

  oxid::shopConfigSinleAction { $configKeys:
    shopid   => $shopid,
    configs  => $configs,
    host     => $host,
    port     => $port,
    db       => $db,
    user     => $user,
    password => $password
  }
}