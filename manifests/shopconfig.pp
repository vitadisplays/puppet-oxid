define oxid::shopConfigS (
  $shopid   = $oxid::params::default_shopid,
  $configs,
  $host     = $oxid::params::db_host,
  $port     = $oxid::params::db_port,
  $db       = $oxid::params::db_name,
  $user     = $oxid::params::db_user,
  $password = $oxid::params::db_password) {
  $value = $configs[$name]
  $query = "UPDATE oxshops SET ${name}='${value}' WHERE oxid = '${shopid}'"

  oxid::mysql::execSQL { "${name}: ${query}":
    query    => $query,
    host     => $host,
    db       => $db,
    port     => $port,
    user     => $user,
    password => $password
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
  if defined(Class[oxid]) {
    Class[oxid] -> Oxid::ShopConfig[$name]
  }
  
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