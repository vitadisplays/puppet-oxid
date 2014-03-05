include mysql_exec

define oxid::mysql::initdb (
  $db,
  $host           = $oxid::mysql::params::default_host,
  $port           = $oxid::mysql::params::default_port,
  $user           = $oxid::mysql::params::default_user,
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
}

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

define oxid::mysql::execFile (
  $db,
  $host        = $oxid::mysql::params::default_host,
  $port        = $oxid::mysql::params::default_port,
  $user        = $oxid::mysql::params::default_user,
  $password,
  $source      = undef,
  /*$extract_cmd = undef,
  $unless      = undef,
  $cwd         = undef,*/
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

  /*$extra_options = $charset ? {
    undef   => "",
    default => " --default-character-set=${charset}"
  }

  if $extract_cmd != undef {
    if !defined(Class[oxid::package::packer]) {
      include oxid::package::packer
    }

    exec { "${name}: ${extract_cmd} < ${source} | mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='******' '${db}'"
    :
      command => "${extract_cmd} < ${source} | mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='${password}' '${db}'",
      path    => $oxid::params::path,
      unless  => $unless,
      cwd     => $cwd,
      timeout => $timeout,
      require => Class[::mysql::client, oxid::package::packer]
    }
    
    mysql_exec {$name: 
      host => $host,
      port => $port,
      user => $user,
      password => $password,
      file => $myfile,
      charset => $charset,
      require => Class[::mysql::client, oxid::package::packer]      
    }
  } else {
    exec { "${name}: mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='******' '${db}' < ${myfile}":
      command => "mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='${password}' '${db}' < ${myfile}",
      path    => $oxid::params::path,
      unless  => $unless,
      cwd     => $cwd,
      timeout => $timeout,
      require => Class[::mysql::client]
    }
  }*/
  
  mysql_import { $myfile:
    db_host     => $host,
    db_port     => $port,
    db_user     => $user,
    db_password => $password,
    db_name => $db,
    db_charset  => $charset,
    require  => Class[::mysql::client]
  }
}

define oxid::mysql::execDirectory (
  $db,
  $host      = $oxid::mysql::params::default_host,
  $port      = $oxid::mysql::params::default_port,
  $user      = $oxid::mysql::params::default_user,
  $password,
  $directory = undef,
  $pattern   = "*.sql",
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

  /*$extra_options = $charset ? {
    undef   => "",
    default => " --default-character-set=${charset}"
  }

  exec { "${name}: find '${mydir}' -iname '${pattern}' | while read i; do mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='******' '${db}' < \"\$i\" ; done"
  :
    command => "find '${mydir}' -iname '${pattern}' | while read i; do mysql${extra_options} --host='${host}' --port=$port --user='${user}' --password='${password}' '${db}' < \"\$i\" ; done",
    path    => $oxid::params::path,
    timeout => $timeout,
    require => Class[::mysql::client]
  }*/

  mysql_import { $mydir:
    db_host     => $host,
    db_port     => $port,
    db_user     => $user,
    db_password => $password,
    db_name => $db,
    db_charset  => $charset,
    require  => Class[::mysql::client]
  }
}

define oxid::mysql::execSQL (
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

  /*exec { "${myquery}":
    command => "mysql --host='${host}' --port=$port --user='${user}' --password='${password}' '${db}' -e \"${myquery}\"",
    path    => $oxid::params::path,
    unless  => $unless,
    timeout => $timeout,
    require => Class[::mysql::client]
  }*/
  
  mysql_query { $myquery:
    db_host     => $host,
    db_port     => $port,
    db_user     => $user,
    db_password => $password,
    require  => Class[::mysql::client]
  }
}

