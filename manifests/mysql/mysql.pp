/*define oxid::mysql::initdb (
  $db,
  $host           = $oxid::params::db_host,
  $port           = $oxid::params::db_port,
  $user           = $oxid::params::db_user,
  $password,
  $charset = $oxid::mysql::params::default_db_charset,
  $collation = $oxid::mysql::params::default_db_collation,
  $grant_user     = undef,
  $grant_password = undef,
  $grant_host     = 'localhost',
  $grant_privs    = 'ALL') {
  $real_grant_user = $grant_user ? {
    undef   => $user,
    default => $grant_user
  }
  $real_grant_password = $grant_user ? {
    undef   => $password,
    default => $grant_password
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }
  
  mysql_query { "DROP DATABASE IF EXISTS ${db}; CREATE DATABASE ${db} CHARACTER SET ${charset} COLLATE ${collation}; GRANT ${grant_privs} ON ${db}.* TO ${real_grant_user}@${grant_host} IDENTIFIED BY '${real_grant_password}'; FLUSH PRIVILEGES;":
    db_host     => $host,
    db_port     => $port,
    db_user     => $user,
    db_password => $password,
    db_charset  => $charset,
    require  => Class[::mysql::client]
  }
}*/

/*define oxid::mysql::createdb (
  $db,
  $host    = $oxid::mysql::params::default_host,
  $port    = $oxid::mysql::params::default_port,
  $user    = $oxid::mysql::params::default_user,
  $password,
  $charset = $oxid::mysql::params::default_db_charset,
  $collation = $oxid::mysql::params::default_db_collation) {  

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }


  mysql_query { $name:
    host     => $host,
    port     => $port,
    user     => $user,
    password => $password,
    query     => "CREATE DATABASE ${db} CHARACTER SET ${charset} COLLATE ${collation};",
    charset  => $charset,
    require  => Class[::mysql::client, oxid::package::packer]
  }
}

define oxid::mysql::grantdb (
  $db,
  $host           = $oxid::mysql::params::default_host,
  $port           = $oxid::mysql::params::default_port,
  $user           = $oxid::mysql::params::default_user,
  $password,
  $grant_user     = undef,
  $grant_password = undef,
  $grant_host     = 'localhost',
  $grant_privs    = 'ALL') {
  $real_grant_user = $grant_user ? {
    undef   => $user,
    default => $grant_user
  }
  $real_grant_password = $grant_user ? {
    undef   => $password,
    default => $grant_password
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  
  mysql_query { $name:
    host     => $host,
    port     => $port,
    user     => $user,
    password => $password,
    query     => "GRANT ${grant_privs} ON ${db}.* TO ${real_grant_user}@${grant_host} IDENTIFIED BY '${real_grant_password}'; FLUSH PRIVILEGES;",
    require  => Class[::mysql::client]
  }
}

define oxid::mysql::dropdb (
  $db,
  $host = $oxid::mysql::params::default_host,
  $port = $oxid::mysql::params::default_port,
  $user = $oxid::mysql::params::default_user,
  $password) {
  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }
  
  mysql_query { $name:
    host     => $host,
    port     => $port,
    user     => $user,
    password => $password,
    query     => "DROP DATABASE IF EXISTS ${db};",
    require  => Class[::mysql::client]
  }
}*/

/*define oxid::mysql::execFile (
  $db,
  $host        = $oxid::mysql::params::default_host,
  $port        = $oxid::mysql::params::default_port,
  $user        = $oxid::mysql::params::default_user,
  $password,
  $source      = undef,
  $charset     = undef,
  $timeout     = 300) {
  if $source != undef {
    $myfile = $source
  } else {
    $myfile = $name
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  
  mysql_import { $myfile:
    db_host     => $host,
    db_port     => $port,
    db_user     => $user,
    db_password => $password,
    db_name => $db,
    db_charset  => $charset,
    require  => Class[::mysql::client]
  }
}*/

/*define oxid::mysql::execDirectory (
  $db,
  $host      = $oxid::mysql::params::default_host,
  $port      = $oxid::mysql::params::default_port,
  $user      = $oxid::mysql::params::default_user,
  $password,
  $directory = undef,
  $charset   = undef,
  $timeout   = 300) {
  if $directory != undef {
    $mydir = $directory
  } else {
    $mydir = $name
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }

  mysql_import { $mydir:
    db_host     => $host,
    db_port     => $port,
    db_user     => $user,
    db_password => $password,
    db_name => $db,
    db_charset  => $charset,
    require  => Class[::mysql::client]
  }
}*/

/*define oxid::mysql::execSQL (
  $db,
  $host    = $oxid::mysql::params::default_host,
  $port    = $oxid::mysql::params::default_port,
  $user    = $oxid::mysql::params::default_user,
  $password,
  $query   = undef,
  $unless  = undef,
  $timeout = 300) {
  $myquery = $query ? {
    undef   => $name,
    default => $query
  }

  if !defined(Class[::mysql::client]) {
    include ::mysql::client
  }
  
  mysql_query { $myquery:
    db_host     => $host,
    db_port     => $port,
    db_user     => $user,
    db_password => $password,
    db_name => $db,
    require  => Class[::mysql::client]
  }
}*/

