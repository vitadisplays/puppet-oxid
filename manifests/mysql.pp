class oxid::mysql::server($user = "root", $password, $config_content = undef) {
  include oxid::common::params
  include oxid::mysql::params
  $module_path = get_module_path('oxid')
  
  package { $oxid::mysql::params::packages :
    ensure  => installed
  }

  if ($config_content != undef) {
    file { "/etc/mysql/my.cnf":
      owner   => "root",
      group   => "root",
      content => $config_content,
      notify  => Service["mysql"],
      require => Package[$oxid::mysql::params::server_package_name],
    } 
  }
  
  service { "mysql":
    enable   => true,
    ensure   => running,
    require  => Package[$oxid::mysql::params::server_package_name],
    provider => 'upstart',
  } ->

  exec { "mysql-set-password":
    unless  => "mysqladmin -uroot -p$password status",
    path    => ["/bin", "/usr/bin"],
    command => "mysqladmin -uroot password $password",
    require => Service["mysql"],
  }

  define createdb ($db, $host = "localhost", $user = "root", $password, $grant_user = undef, $grant_password = undef) {
    $real_grant_user = $grant_user ? { undef => $user, default => $grant_user }
    $real_grant_password = $grant_user ? { undef => $password, default => $grant_password }
    
    exec { "mysql-create-${host}-${db}-db":
      unless  => "mysql -h ${host} -u${user} -p${password} ${db}",
      path    => ["/bin", "/usr/bin"],
      command => "mysql -h ${host} -u${user} -p${password} -e \"create database ${db}; grant all on ${db}.* to ${real_grant_user}@localhost identified by '${real_grant_password}';FLUSH PRIVILEGES;\"",
    }
  }
  
  define dropdb ($db, $host = "localhost", $user = "root", $password) {
    exec { "mysql-drop-${host}-${db}-db":
      path    => ["/bin", "/usr/bin"],
      command => "mysql -h ${host} -u${user} -p${password} -e \"drop database IF EXISTS ${db};\"",
    }
  }
  
  define execFile ($db, $host = "localhost", $port = 3306,  $user, $password, $sql_file = undef, $unless = undef) {
    if $sql_file != undef {
      $myfile = $sql_file
    } else {
      $myfile = $name
    }
    
    exec { "mysql-execFile-${host}-${myfile}":
      command => "mysql -P ${port} -h ${host} -u${user} -p${password} ${db} < ${$myfile}",
      onlyif => "test -f ${myfile}",
      path => "/usr/bin:/usr/sbin:/bin",
      unless => $unless
    }
  }
  
  define execSQL ($db, $host = "localhost", $user, $password, $query = undef, $unless = undef) {
    $myquery = $name
    
    if $query != undef {
      $myquery = $query
    }
    
    exec { "mysql-execSQL-${host}-${myquery}":
      command => "mysql -h ${host} -u${user} -p${password} ${db} -e \"${myquery}\"",
      path => "/usr/bin:/usr/sbin:/bin",
      unless => $unless
    }
  }
}

