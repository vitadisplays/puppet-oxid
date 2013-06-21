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
    $configurations,
    $config_content,
    $htaccess_content = undef
    ) {    
  
  /*$config_keys = keys($configurations)*/
  
  include oxid::stages
	include 'stdlib'
	include oxid::params
	include oxid::common::params  
       
  oxid::install{"oxid-base-install": 
    shop_dir => $configurations['sShopDir'],
    source => $source,
    db_host         => $configurations['dbHost'],
    db_name         => $configurations['dbName'],
    db_user         => $configurations['dbUser'],
    db_password     => $configurations['dbPwd'],
    utf8            => $configurations['iUtfMode'],
    mysql_user => $configurations['mysql_user'],
    mysql_password => $configurations['mysql_password']    
  }
  
  file { "${configurations['sShopDir']}/config.inc.php":
      ensure => 'present',
      mode => "0444",
      content => $config_content,
      require => Oxid::Install["oxid-base-install"]
  } 
  
  if $htaccess_content != undef {
	  file { "${configurations['sShopDir']}/.htaccess":
	      ensure => 'present',
	      mode => "0444",
	      content => $htaccess_content,
      require => Oxid::Install["oxid-base-install"]
	  }
  } else {
    file { "${configurations['sShopDir']}/.htaccess":
        ensure => 'present',
        mode => "0444",
      require => Oxid::Install["oxid-base-install"]
    }
  }
  
  /*oxid::baseconfig{ $config_keys : 
      config_file     => "${configurations['sShopDir']}/config.inc.php",
      configurations => $configurations,
      require => Oxid::Install ["oxid-base-install"]
  }*/  

  class {
    oxid::lastcheck: 
    shop_dir => $configurations['sShopDir'], 
    compile_dir => $configurations['sCompileDir'],
    stage => last;    
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
    
    exec { "oxid-delete-dir":
      command => "rm -r ${shop_dir}",
      path    => "/usr/bin:/usr/sbin:/bin",
      onlyif  => "test -d ${shop_dir}"
    } ->
     
    exec { "oxid-dir":
      command => "mkdir -p ${shop_dir}",
      path    => "/usr/bin:/usr/sbin:/bin",
      require => Exec["oxid-delete-dir"]
    } ->
    
    oxid::unpack{$source: destDir => $shop_dir } ->
    
    mysql::server::createdb { "oxid-create-${db_name}":
      host     => $db_host,
      db       => $db_name,
      user     => $mysql_user,
      password => $mysql_password,
      grant_user     => $db_user,
      grant_password => $db_password
    } ->
    
    mysql::server::execFile { "oxid-import-base-${db_name}":
      host     => $db_host,
      db       => $db_name,
      user     => $db_user,
      password => $db_password,
      sql_file     => "${shop_dir}/setup/sql/database.sql"
    }
  
    if $utf8 == '1' {
      mysql::server::execFile { "oxid-utf8-${db_name}":
        db       => $db_name,
        user     => $db_user,
        password => $db_password,
        sql_file => "${shop_dir}/setup/sql/latin1_to_utf8.sql",
        require  => Mysql::Server::ExecFile ["oxid-import-base-${db_name}"]
      }
    }    
  }

  /*define baseconfig ($config_file, $configurations) {
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
        pattern     => "/(\\\$this\\-\\>${name}\\s*=\\s*)(.*)(;)/",
        replacement => "\$1${config_value}\$3"
    } 
  }

  define replace($file, $pattern, $replacement) {
    $module_path = get_module_path('oxid')
    $pattern_no_slashes = regsubst($pattern, '/', '\\/', 'G', 'U')
    $replacement_no_slashes = regsubst($replacement, '/', '\\/', 'G', 'U')

    exec { "${name}": command => "perl -pi -e \"s/$pattern_no_slashes/$replacement_no_slashes/\" '$file'", path => "/usr/bin:/usr/sbin:/bin"}
    
    exec { "php -f ${module_path}/functions/replace_in_files.php '${file}' '${pattern_no_slashes}' \"${replacement_no_slashes}\"":
      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
    }
  }  */
 
  define syncData($url, $excludes = undef, $dir = $oxid::params::shop_dir, $private_key = undef) { 
    if $excludes != undef {
      $real_join = join($excludes, " --exclude=")
      $real_exclude = " --exclude=${real_join}"
    } else {
      $real_exclude = ""
    }
    
    if $private_key != undef {
      $real_privatekey_option = " -i ${private_key}"
    } else {
      $real_privatekey_option = ""
    }
                      
	  exec { "rsync -avz${real_exclude} -e 'ssh ${real_privatekey_option} -oStrictHostKeyChecking=no' ${url} ${dir}":
			path   => "/usr/bin:/usr/sbin:/bin",
			timeout => 0
		}
  }
  
  define syncSQL($url, $remote_config, $local_config, $private_key = undef) {
    if $private_key != undef {
      $real_privatekey_option = " -i ${private_key}"
    } else {
      $real_privatekey_option = ""
    }
                         
    exec { "ssh ${real_privatekey_option} -oStrictHostKeyChecking=no -C ${url} mysqldump --add-drop-table --allow-keywords --compress -u ${remote_config['dbUser']} --password=${remote_config['dbPwd']} ${remote_config['dbName']} | mysql -u ${local_config['dbUser']} --password=${local_config['dbPwd']} -D ${local_config['dbName']}":
      path   => "/usr/bin:/usr/sbin:/bin",
      timeout => 0
    }
  }
  
  define importData ($shop_dir = $oxid::params::shop_dir) {
    $work_dir = "${oxid::common::params::tmp_dir}/oxid-data"

    exec { "${name}-mkdirs":
      command => "mkdir -p ${work_dir}/data",
      path   => "/usr/bin:/usr/sbin:/bin"      
    }
    
    exec { "${name}-wget-data":
      command => "wget --progress=bar ${name} -O ${work_dir}/data/data.tar.gz",
      path   => "/usr/bin:/usr/sbin:/bin" 
    }  
    
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
  
  define unpack($destDir = $oxid::params::shop_dir) {
    $module_path = get_module_path('oxid')
      
    case $name {
      /^(file:)(\/\/)*(.*\.phar$)/ : {                    
                    exec { "unphar ${name}":
                      command => "php -f ${module_path}/functions/oxid/phar-extract.php '$3' '${destDir}'", 
                      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
                    }
                  }
      /^(file:)(\/\/)*(.*\.zip$)/ : {                    
                    exec { "unzip ${name}":
                      command => "unzip -o --qq '$3'",
                      cwd => $destDir,
                      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
                    }
                  }
      /^(file:)(\/\/)*(.*\.tar.gz$)/ : {                    
                    exec { "untar/gz ${name}":
                      command => "tar -zxf '$3'",
                      cwd => $destDir,
                      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
                    }
                  }                                    
       default: { 
        fail("Unrecognized schema: $name") 
        }                  
    }
  }
  
  define extractPhar($shop_dir = $oxid::params::shop_dir) {
    $module_path = get_module_path('oxid')
      
    case $name {
      /^(file:)(\/\/)*(.*)/ : {                    
                    exec { "extractPhar ${name}":
                      command => "php -f ${module_path}/functions/oxid/phar-extract.php $3 ${shop_dir}", 
                      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
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
      if (is_array($modules) or (is_string($modules)) and $modules != "*") {
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
    
    $cmd = inline_template('<%= require "json"; JSON.generate @jsonHash %>')
    
    exec { "oxid-module '${cmd}'":        
        command => "php -f ${module_path}/functions/oxid/oxid-modules.php '${cmd}'", 
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
      } 
  }
    
  define configSingleAction($shopid, $configs, $host, $port, $db, $user, $password, $config_key) {
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
    
    $cmd = inline_template('<%= require "json"; JSON.generate @jsonHash %>')
    
    exec { "oxid-config ${cmd}":        
        command => "php -f ${module_path}/functions/oxid/oxid-config.php '${cmd}'", 
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
      }
  }
  
  define config($shopid, $ensure = "present", $configs, $host = "localhost", $port = $oxid::params::db_port, $db = $oxid::params::db_name, $user = $oxid::params::db_user, $password = $oxid::params::db_password, $config_key = $oxid::params::config_key) {
    $configKeys = keys($configs)
    
    if $ensure == 'absent' {
	     oxid::removeconfig { $configKeys: 
	        shopid => $shopid, 
          host => $host, 
          port => $port,
          db => $db,
          user => $user, 
          password => $password
	     }
    } else {
      oxid::configSingleAction { $configKeys:
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
  }
  
  define removeconfig($shopid, $host = "localhost", $port = $oxid::params::db_port, $db = $oxid::params::db_name, $user = $oxid::params::db_user, $password = $oxid::params::db_password) {
    $module_path = get_module_path('oxid')
    $jsonHash = { 
        'command' => 'remove', 
        'varname' => $name, 
        'shopid' => $shopid,
        'host' => "${host}:${port}",
        'db' => $db,
        'user' => $user,
        'password' => $password
      }
    
    $cmd = inline_template('<%= require "json"; JSON.generate @jsonHash %>')
    
    exec { "oxid-config ${cmd}":        
        command => "php -f ${module_path}/functions/oxid/oxid-config.php '${cmd}'", 
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
     }
  }
  
  define shopconfigSinleAction($shopid, $configs, $host = "localhost", $port = $oxid::params::db_port, $db = $oxid::params::db_name, $user = $oxid::params::db_user, $password = $oxid::params::db_password) {
    $value = $configs[$name]
    $query = "UPDATE oxshops SET ${name}='${value}' WHERE oxid = '${shopid}'"
    
    exec { $query:
      command => "mysql -h ${host} -P ${port} -u${user} -p${password} ${db} -e \"${query}\"",
      path   => "/usr/bin:/usr/sbin:/bin"
    }
  }
  
  define shopconfig($shopid, $configs, $host = "localhost", $port = $oxid::params::db_port, $db = $oxid::params::db_name, $user = $oxid::params::db_user, $password = $oxid::params::db_password) {
    $configKeys = keys($configs)
    
     oxid::shopconfigSinleAction{$configKeys: 
       shopid => $shopid,
       configs => $configs,
       host => $host,
       port => $port,
       db => $db,
       user => $user,
       password => $password
     }
  }
  
  define update($shop_dir, $update_package, $changed_full = false, $run_cli = false, $run_cli_template = undef) {
    $filename = inline_template('<%= File.basename(update_package) %>')

    $cmds = ["cp -R -f updateApp/ \"${shop_dir}\"", "cp -R -f copy_this/* \"${shop_dir}\""]     
     
    exec { "unzip '${update_package}' -d '${filename}'":        
        cwd => "${oxid::common::params::tmp_dir}",
        path   => "/usr/bin:/usr/sbin:/bin",
        unless => "test -d '${oxid::common::params::tmp_dir}/${filename}'",
        timeout => 120,
        require => Package['unzip']
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
           exec { ["php -f '${shop_dir}/updateApp/run_cli.php'"] :        
            path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
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

class oxid::lastcheck($shop_dir, $compile_dir, $owner = "www-data", $group = "www-data") {
    exec { "oxid-check-root-dir": 
      command => "chown -R ${owner}:${group} ${shop_dir} & chmod -R ug+rw ${shop_dir}", 
      path => "/usr/bin:/usr/sbin:/bin"
    }
     
    /*file { "oxid-check-root-dir":
      path => "${shop_dir}",
      ensure => 'present',
      mode => "+ug+rw",
      owner => $owner,
      group => $group,
      recurselimit => 0
    }
    
    file { "oxid-check-oxid-config":
      path => "${shop_dir}/config.inc.php",
      ensure => 'present',
      mode => "0444",
      require => Exec["oxid-check-root-dir"]
    }
    
    file { "oxid-check-oxid-htaccess":
      path => "${shop_dir}/.htaccess",
      ensure => 'present',
      mode => "0444",
      require => Exec["oxid-check-root-dir"]
    }*/
    
    file { "${shop_dir}/tmp":
      ensure => 'present',
      mode => "ug+rw",
      require => Exec["oxid-check-root-dir"]
    }  

    file { "${shop_dir}/setup":
      ensure => 'absent',
      force => true
    }
    
    file { "${shop_dir}/updateApp":
      ensure => 'absent',
      force => true
    }
     
    /*exec { "oxid-check-root-dir": 
      command => "chown -R ${owner}:${group} ${shop_dir} & chmod -R ug+rw ${shop_dir}", 
      path => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "oxid-check-oxid-config": 
      command => "chown -R ${owner}:${group} ${shop_dir}/config.inc.php & chmod -R 0444 ${shop_dir}/config.inc.php", 
      path => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "oxid-check-oxid-htaccess": 
      command => "chown -R ${owner}:${group} ${shop_dir}/.htaccess & chmod -R 0444 ${shop_dir}/.htaccess", 
      path => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "oxid-check-compile-dir": 
      command => "chown -R ${owner}:${group} ${compile_dir} & chmod -R ug+rw ${compile_dir}", 
      path => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "oxid-clean":
        command => "rm -r -f ${compile_dir}/*",
        path   => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "oxid-check-remove-setup": 
      command => "rm -r -f ${shop_dir}/setup", 
      onlyif => "test -d ${shop_dir}/setup",
      path => "/usr/bin:/usr/sbin:/bin"
    } ->
    
    exec { "oxid-check-remove-updatApp": 
      command => "rm -r -f ${shop_dir}/updatApp", 
      onlyif => "test -d ${shop_dir}/updatApp",
      path => "/usr/bin:/usr/sbin:/bin"
    } ->*/
     
	  exec {"oxid-updateviews-${configurations['sShopDir']}":
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        command => "php -r 'function getShopBasePath() { return \"${configurations['sShopDir']}/\"; } function isAdmin() { return true; } require_once getShopBasePath().\"core/oxfunctions.php\"; require_once getShopBasePath().\"core/oxsupercfg.php\"; require_once getShopBasePath().\"core/oxdb.php\"; oxDb::getInstance()->updateViews(); exit(0);'",
  }
}