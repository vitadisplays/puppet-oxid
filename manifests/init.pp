# Class: vitadisplays_oxid
#
# This module manages vitadisplays_oxid
#
# Parameters: none
#
# Actions:
#
# Requires: see Modulefile
#
# Sample Usage:
#

class oxid(
    $source,
    $vhosts = undef,
    $configurations,
    $archives = undef,
    $dataSources = undef,
    $sqlSources = undef
    ) {    
  
  $config_keys = keys($configurations)
  
  include oxid::stages
	include 'stdlib'
	include oxid::params
	include oxid::common::params  
	include oxid::mysql::params
	include oxid::apache::params
	include oxid::php::params
  
  class {
    oxid::common: stage => pre;    
  } ->
  
  class {
    oxid::php:;    
  }   
  
  if ($vhosts != undef) {
    class {
      oxid::apache:   vhosts => $vhosts;    
    }
  }  
  
  oxid::install{"${name}-base-install": 
    shop_dir => $configurations['sShopDir'], 
    source => $source,
    db_host         => $configurations['dbHost'],
    db_name         => $configurations['dbName'],
    db_user         => $configurations['dbUser'],
    db_password     => $configurations['dbPwd'],
    utf8            => $configurations['iUtfMode'],
    mysql_user => $configurations['mysql_user'],
    mysql_password => $configurations['mysql_password'],
    require => Class [oxid::php]
  } ->  

  oxid::config{ $config_keys : 
      config_file     => "${configurations['sShopDir']}/config.inc.php",
      configurations => $configurations
  }  
  
  $requires = [Oxid::Config[$config_keys], Oxid::Install["${name}-base-install"]]
  
  if $dataSources != undef {
    importData {$dataSources: shop_dir => $configurations['sShopDir'], require => $requires } 
  }
  
  if $sqlSources != undef {
    importSQL {$sqlSources: shop_dir => $configurations['sShopDir'], host => $configurations['dbHost'], db => $configurations['dbName'], mysql_user => $configurations['dbUser'], mysql_password => $configurations['dbPwd'], require => $requires }
  }
  
  if $archives != undef {
    extractPhar {$archives: require => $requires}
  }
  
  clean { "${name}-clean": require => $requires} ->
  
  check { "${name}-post-check": shop_dir => $configurations['sShopDir'], compile_dir => $configurations['sCompileDir']}  
  
  define updateViews($shop_dir) {
    exec {"oxid-updateviews-${shop_dir}":
      path    => "/usr/bin:/usr/sbin:/bin",
      command => "php -c /etc/php5/apache2/php.ini -r 'function getShopBasePath() { return \"${shop_dir}/\"; } function isAdmin() { return true; } require_once getShopBasePath().\"core/oxfunctions.php\"; require_once getShopBasePath().\"core/oxsupercfg.php\"; require_once getShopBasePath().\"core/oxdb.php\"; oxDb::getInstance()->updateViews(); exit(0);'",
      notify => Exec["force-reload-apache2"]
    } 
  }
  
  define install (
    $mysql_user = "root",
    $mysql_password,    
    $shop_dir, 
    $source,
    $db_host,
    $db_name,
    $db_user,
    $db_password,
    $utf8  = '0'
    ) {
    $process_name = $name
     
    exec { "${process_name}-delete-dir":
      command => "rm -r -f ${shop_dir}",
      path    => "/usr/bin:/usr/sbin:/bin",
      onlyif  => "test -d ${shop_dir}"
    } ->
     
    exec { "${process_name}-create-dir":
      command => "mkdir -p ${shop_dir}",
      path    => "/usr/bin:/usr/sbin:/bin",
      unless  => "test -d ${shop_dir}",
      require => Exec["${process_name}-delete-dir"]
    }
    
    case $source {
      /^(file:)(\/\/)*(.*)/ : { 
          exec { "${process_name}-source":
            cwd     => "${shop_dir}",
            command => "unzip $3",
            path    => "/usr/bin:/usr/sbin:/bin",
            require => Exec["${process_name}-create-dir"]
          }                   
       }          
       default: { 
        fail("Unrecognized schema.") 
        }                  
    }
  
    /*mysql::server::dropdb { "${process_name}-drop-${db_name}":
      host     => $db_host,
      db       => $db_name,
      user     => $mysql_user,
      password => $mysql_password,
      require => Exec["${process_name}-source"]
    } ->*/
    
    mysql::server::createdb { "${process_name}-create-${db_name}":
      host     => $db_host,
      db       => $db_name,
      user     => $mysql_user,
      password => $mysql_password,
      grant_user     => $db_user,
      grant_password => $db_password,
      require => Exec["${process_name}-source"]
    } ->
  
    mysql::server::execFile { "${process_name}-import-base-${db_name}":
      host     => $db_host,
      db       => $db_name,
      user     => $db_user,
      password => $db_password,
      sql_file     => "${shop_dir}/setup/sql/database.sql",
      require => [Exec["${process_name}-source"]],
      notify => Exec["oxid-updateviews-${shop_dir}"]
    }
  
    if $utf8 == '1' {
      mysql::server::execFile { "${process_name}-convert-utf8-db":
        db       => $db_name,
        user     => $db_user,
        password => $db_password,
        sql_file => "${shop_dir}/setup/sql/latin1_to_utf8.sql",
        require  => Mysql::Server::ExecFile ["${process_name}-import-base-db"],
        notify => Exec["oxid-updateviews-${shop_dir}"]
      }
    }
  }
  
  define clean ($shop_dir = $oxid::params::shop_dir, $comple_dir = $oxid::params::compile_dir) {
    $process_name = $name
    exec { "${process_name}-${comple_dir}":
      command => "rm -r -f ${comple_dir}/tmp/*",
      path   => "/usr/bin:/usr/sbin:/bin",
      unless => "test -d ${comple_dir}/tmp"
    }
  }

  define config ($config_file, $configurations) {
    $raw_value = $configurations[$name]
    
    $config_value1 = type($raw_value) ? {
      'string' => "'${raw_value}'",
      default => $raw_value
    }
    
    $config_value = $config_value1 ? {
      /(^')('.*')('$)/ => "$2",
      default => $config_value1
    }
    
    replace { "oxid-config ${name} => ${config_value}":
        file        => $config_file,
        pattern     => "(\\\$this->${name}\\s*=\\s*)(.*)(;)",
        replacement => "\\1${config_value}\\3"
    } 
  }

  define replace ($file, $pattern, $replacement) {
    $pattern_no_slashes = regsubst($pattern, '/', '\\/', 'G', 'U')
    $replacement_no_slashes = regsubst($replacement, '/', '\\/', 'G', 'U')

    exec { "${name}": command => "perl -pi -e \"s/$pattern_no_slashes/$replacement_no_slashes/\" '$file'", path => "/usr/bin:/usr/sbin:/bin"}
  }  
  
  define check ($shop_dir, $compile_dir) { 
    exec { "${name}-root-dir": 
      command => "chown -R www-data:www-data ${shop_dir} & chmod -R 0775 ${shop_dir}", 
      onlyif => "test -d ${shop_dir}",
      path => "/usr/bin:/usr/sbin:/bin"
    }
    
    exec { "${name}-oxid-config": 
      command => "chown -R www-data:www-data ${shop_dir}/config.inc.php & chmod -R 0444 ${shop_dir}/config.inc.php", 
      onlyif => "test -f ${shop_dir}/config.inc.php",
      path => "/usr/bin:/usr/sbin:/bin"
    }
    
    exec { "${name}-oxid-htaccess": 
      command => "chown -R www-data:www-data ${shop_dir}/.htaccess & chmod -R 0444 ${shop_dir}/.htaccess", 
      onlyif => "test -f ${shop_dir}/.htaccess",
      path => "/usr/bin:/usr/sbin:/bin"
    }
    
    exec { "${name}-compile-dir": 
      command => "chown -R www-data:www-data ${compile_dir} & chmod -R 0775 ${compile_dir}", 
      onlyif => "test -d ${compile_dir}",
      path => "/usr/bin:/usr/sbin:/bin"
    }
    
    exec { "${name}-remove-setup": 
      command => "rm -r -f ${shop_dir}/setup", 
      onlyif => "test -d ${shop_dir}/setup",
      path => "/usr/bin:/usr/sbin:/bin"
    }
  }
 
  define importData ($shop_dir = $oxid::params::shop_dir) {
    $work_dir = "${oxid::common::params::tmp_dir}/oxid-data"

    exec { "${name}-mkdirs":
      command => "mkdir -p ${work_dir}/data",
      path   => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "${name}-wget-data":
      command => "wget --progress=bar ${name} -O ${work_dir}/data/data.tar.gz",
      path   => "/usr/bin:/usr/sbin:/bin"
    } ->  
    
    exec { "${name}-untar-data":
      command => "tar xvfz ${work_dir}/data/data.tar.gz -C ${shop_dir}",
      path   => "/usr/bin:/usr/sbin:/bin"
    }  
  }
  
  define importSQL ($shop_dir, $host = "localhost", $db = $oxid::params::db_name, $mysql_user = $oxid::params::db_user, $mysql_password = $oxid::params::db_password) {
    $work_dir = "${oxid::common::params::tmp_dir}/oxid-data"

    exec { "${name}-importSQL-mkdir":
      command => "mkdir -p ${work_dir}/sql",
      path   => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "${name}-wget-sql":
      command => "wget --progress=bar ${name} -O ${work_dir}/sql/sql.tar.gz",
      path   => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "${name}-untar-sql":
      command => "tar xvfz ${work_dir}/sql/sql.tar.gz -C ${work_dir}/sql/",
      path   => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "${name}-mysql-sql":
      command => "sh -c 'for file in ${work_dir}/sql/*.sql; do mysql -h ${host} -u${mysql_user} -p${mysql_password} ${db} < \$file ; done'",
      path   => "/usr/bin:/usr/sbin:/bin"
    }     
  }
  
  define extractPhar($shop_dir = $oxid::params::shop_dir) {
    $module_path = get_module_path('oxid')
      
    case $name {
      /^(file:)(\/\/)*(.*)/ : {                    
                    exec { "extractPhar-${name}":
                      command => "phar-extract.php $3 ${shop_dir}", 
                      path   => "${module_path}/functions/oxid"
                    }
                  }
                  
       default: { 
        fail("Unrecognized schema: $name") 
        }                  
    }
  }
 
  define module($shopid, $modules = undef, $ensure = "present", $host = "localhost", $port = $oxid::params::db_port, $db = $oxid::params::db_name, $user = $oxid::params::db_user, $password = $oxid::params::db_password, $config_key = $oxid::params::config_key) {    
    $module_path = get_module_path('oxid')
    
    if $ensure == 'absent' {
      if (is_array($modules) or is_string($modules)) and $modules != "*" {
         $jsonHash = { 
            'command' => "delete", 
            'module' => $modules,
            'shopid' => $shopid,
            'host' => "${host}:${port}",
            'db' => $db,
            'user' => $user,
            'password' => $password
          }
       } elsif is_string($modules) and $modules == "*" { 
         $jsonHash = { 
            'command' => "clear", 
            'shopid' => $shopid,
            'host' => "${host}:${port}",
            'db' => $db,
            'user' => $user,
            'password' => $password
          }         
       } else {
         err("Modules for delete cammand should be a array or string.")
       }
    } elsif $ensure == "present" { 
      $jsonHash = { 
            'command' => "add", 
            'module' => $modules,
            'shopid' => $shopid,
            'host' => "${host}:${port}",
            'db' => $db,
            'user' => $user,
            'password' => $password,
            'configkey' => $config_key
          }
    } elsif $ensure == "override" { 
      $jsonHash = { 
            'command' => "set", 
            'module' => $modules,
            'shopid' => $shopid,
            'host' => "${host}:${port}",
            'db' => $db,
            'user' => $user,
            'password' => $password,
            'configkey' => $config_key
          }
    } else {
      err("Module ensure should be present, absent or override")
    }
    
    $cmd = inline_template('<%= require "json"; JSON.generate jsonHash %>')
    
    exec { "oxid-module '${cmd}'":        
        command => "oxid-modules.php '${cmd}'", 
        path   => "${module_path}/functions/oxid"
      } 
  }
  
  define removeShopConfigSingleAction($shopid, $host, $port, $db, $user, $password) {
    $varname = $name
    $module_path = get_module_path('oxid')
    
    $jsonHash = { 
        'command' => 'remove', 
        'varname' => $varname, 
        'shopid' => $shopid,
        'host' => "${host}:${port}",
        'db' => $db,
        'user' => $user,
        'password' => $password
      }
    
    $cmd = inline_template('<%= require "json"; JSON.generate jsonHash %>')
    
    exec { "oxid-config ${host}:${port} remove ${varname}":        
        command => "oxid-config.php '${cmd}'", 
        path   => "${module_path}/functions/oxid"
      }
  }
    
  define setShopConfigSingleAction($shopid, $configs, $host, $port, $db, $user, $password, $config_key) {
    $varname = $name     
    $module_path = get_module_path('oxid')
    
    if type($configs[$varname]) == hash {
      $vartype = "aarr"
      $varvalue = $configs[$varname] 
    } elsif type($configs[$varname]) == array {
      $vartype = "aar"
      $varvalue = $configs[$varname] 
    } elsif type($configs[$varname]) == boolean {
      $vartype = "bool"
      $varvalue = bool2num($configs[$varname])
    } elsif type($configs[$varname]) == string and ($configs[$varname] == true or $configs[$varname] == false or $configs[$varname] == undef) {
      $vartype = "bool"
      $varvalue = bool2num($configs[$varname])
    } else {
      $vartype = "str"
      $varvalue = $configs[$varname] 
    }
    
    $jsonHash = { 
      'command' => 'set', 
      'vartype' => $vartype, 
      'varname' => $varname, 
      'varvalue' => $varvalue,
      'shopid' => $shopid,
      'host' => "${host}:${port}",
      'db' => $db,
      'user' => $user,
      'password' => $password,
      'configkey' => $config_key
    } 
    
    $cmd = inline_template('<%= require "json"; JSON.generate jsonHash %>')
    
    exec { "oxid-config ${cmd}":        
        command => "oxid-config.php '${cmd}'", 
        path   => "${module_path}/functions/oxid"
      }
  }
  
  define setShopConfig($shopid, $configs, $host = "localhost", $port = $oxid::params::db_port, $db = $oxid::params::db_name, $user = $oxid::params::db_user, $password = $oxid::params::db_password, $config_key = $oxid::params::config_key) {
    $configKeys = keys($configs)
    
    setShopConfigSingleAction { $configKeys:
        shopid => $shopid, 
        configs => $configs, 
        host => $host, 
        port => $port,
        db => $db,
        user => $user, 
        password => $password, 
        config_key => $config_key
    }
  }
  
  define removeShopConfig($shopid, $varnames, $host = "localhost", $port = $oxid::params::db_port, $db = $oxid::params::db_name, $user = $oxid::params::db_user, $password = $oxid::params::db_password) {
    $module_path = get_module_path('oxid')
    $jsonHash = { 
        'command' => 'remove', 
        'varname' => $varnames, 
        'shopid' => $shopid,
        'host' => "${host}:${port}",
        'db' => $db,
        'user' => $user,
        'password' => $password
      }
    
    $cmd = inline_template('<%= require "json"; JSON.generate jsonHash %>')
    
    exec { "oxid-config ${cmd}":        
        command => "oxid-config.php '${cmd}'", 
        path   => "${module_path}/functions/oxid"
     }
  }
  
  define update($shop_dir, $update_package, $changed_full = false, $run_cli = false, $run_cli_template = undef) {
    $filename = inline_template('<%= File.basename(update_package) %>')

    $cmds = ["cp -R -f updateApp/ \"${shop_dir}\"", "cp -R -f copy_this/* \"${shop_dir}\""]     
     
    exec { "unzip '${update_package}' -d '${filename}'":        
        cwd => "${oxid::common::params::tmp_dir}",
        path   => "/usr/bin:/usr/sbin:/bin",
        unless => "test -d '${oxid::common::params::tmp_dir}/${filename}'",
        timeout => 120
     } ->
     
      exec { $cmds:        
        cwd => "${oxid::common::params::tmp_dir}/${filename}",
        path   => "/usr/bin:/usr/sbin:/bin"
     } 
          
     if $run_cli {
         if $run_cli_template != undef {
           $expect_filename = inline_template('<%= File.basename(run_cli_template) %>')
           
           file { "expect-${$name}":
              path    => "${oxid::common::params::tmp_dir}/${expect_filename}",
              owner   => root,
              group   => root,
              mode    => 644,
              content => template($run_cli_template),
              require => Exec[$cmds]
          } ->
            exec { ["${oxid::common::params::tmp_dir}/${expect_filename}"] :        
              path   => "${oxid::common::params::tmp_dir}",
              timeout => 240
            }
         } else {
           exec { ["php '${shop_dir}/updateApp/run_cli.php'"] :        
            path   => "/usr/bin:/usr/sbin:/bin",
            require => Exec[$cmds],
            timeout => 240
          }         
         }      
     }
     
     if $changed_full {
       exec { "cp -R -f changed_full/* \"${shop_dir}\"":
          cwd => "${oxid::common::params::tmp_dir}/${filename}",        
          path   => "/usr/bin:/usr/sbin:/bin",
          require => Exec[$cmds]
       }  
     }  
  }
}
