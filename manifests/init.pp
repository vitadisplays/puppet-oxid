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
    $htaccess_content = undef,
    $force = false
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
    mysql_password => $configurations['mysql_password'],
    config_content => $config_content,
    htaccess_content => $htaccess_content,
    force => $force 
  }

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
    $utf8  = '0',
    $config_content,
    $htaccess_content = undef,
    $force = false
    ) {
    
    $_exists = inline_template("<%= File.exists?('$shop_dir') %>")
    
    /*exec { "oxid-delete-dir":
      command => "rm -r ${shop_dir}",
      path    => "/usr/bin:/usr/sbin:/bin",
      onlyif  => "test -d ${shop_dir}"
    } ->*/
    
    if ($_exists != "true" or $force == true) {
	    exec { "oxid-dir":
	      command => "mkdir -p ${shop_dir}",
	      path    => "/usr/bin:/usr/sbin:/bin"
	    } ->
	    
	    oxid::unpack{$source: destPath => $shop_dir} ->   
    
	    mysql::server::dropdb { "oxid-drop-${db_name}":
	      host     => $db_host,
	      db       => $db_name,
	      user     => $mysql_user,
	      password => $mysql_password
	    } ->
	    
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
	    } ->
	  
		  file { "${shop_dir}/config.inc.php":
		      ensure => 'present',
		      mode => "0444",
		      content => $config_content,
		      notify => Exec["force-reload-httpd-server"]
		  } ->
		  
		  file { "${shop_dir}/.htaccess":
		        ensure => 'present',
		        mode => "0444",
		        content => $htaccess_content,
		        notify => Exec["force-reload-httpd-server"]
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
     } else {
      file { "${shop_dir}/config.inc.php":
          ensure => 'present',
          mode => "0444",
          content => $config_content,
          notify => Exec["force-reload-httpd-server"]
      } ->
      
      file { "${shop_dir}/.htaccess":
            ensure => 'present',
            mode => "0444",
            content => $htaccess_content,
            notify => Exec["force-reload-httpd-server"]
       }
     } 
  }
  
  define importData ($dest_dir, $tmp_dir = undef, $options = undef, $timeout = 18000, $unless = undef) {      
    case $name {     
      /^(https*:)(\/\/)*(.*\.tar\.gz|.*\.zip|.*\.gz|.*\.phar)$/ : {
          if $tmp_dir != undef {
            $real_tmp_Dir = $tmp_dir 
          } else {
		        $real_tmp_Dir = inline_template('<%= Dir.mktmpdir %>')
          }
          
          $filename = "$3"
          $basename = inline_template('<%= File.basename(@filename) %>')
          
	        $real_output_file = "${real_tmp_Dir}/${basename}"
	
	        exec { "wget ${name}":
			      command => "wget ${name} -O ${real_output_file}",
			      path   => "/usr/bin:/usr/sbin:/bin",
			      unless => $unless,
			      timeout => $timeout			      
			    } ->
			    
			    unpack{$real_output_file : 
			        destPath => $dest_dir, 
			        timeout => $timeout,
              require => Exec["wget ${name}"],
              unless => $unless
          }
			    
			    if $tmp_dir == undef {
				    exec { "${name}-remove-tmp-files":
				        command => "rm -f -r ${real_tmp_Dir}",
				        path   => "/usr/bin:/usr/sbin:/bin",
				        unless => $unless,
                require => Unpack[$real_output_file]                
            }			    
				  }    
      }
      
      /^(scp:)(\/\/)*(.*:)(\/)?(.*)$/ : {
        if $name =~ /.*(\.tar\.gz|\.zip|\.gz|\.phar)$/ {
          $extra_options = []
  
          $filename = "$5"
          $basename = inline_template('<%= File.basename(@filename) %>')
        
          $real_output_dir = $tmp_dir ? {undef => inline_template('<%= Dir.mktmpdir %>') , default => $tmp_dir}
          $real_output_file = "${real_output_dir}/${basename}"
        } else {
          $extra_options = ["-r"]
        
          $real_output_dir = $dest_dir
          $real_output_file = $dest_dir
        }      
        
        $real_options = concat($extra_options, $options)
        
        if $options != undef {
          $option_str = join($real_options, ' ')
        } else {
          $option_str = ""
        }
        
        $command = "scp ${option_str} $3$4$5"

        exec { "scp ${name}":
          command => "$command .",
          path   => "/usr/bin:/usr/sbin:/bin",
          cwd    => $real_output_dir,
          unless => $unless,
          timeout => $timeout
        }
        
        if $name =~ /.*(\.tar\.gz|\.zip|\.phar$)/ and $tmp_dir == undef {
          unpack{$real_output_file : 
              destPath => $dest_dir,
              timeout => $timeout,
              require => Exec["scp ${name}"], 
              unless => $unless} ->
          
          exec { "${name}-remove-tmp-files":
              command => "rm -f -r ${tmp_dir}",
              unless => $unless,
              path   => "/usr/bin:/usr/sbin:/bin"
          }
        }        
      } 
      
      /^(file*:)(\/\/)*(.*\.tar\.gz|.*\.zip|.*\.gz|.*\.phar)$/ : {
        unpack{$3 : 
              destPath => $dest_dir,
              unless => $unless,
              timeout => $timeout}
      }
            
      /^(file*:)(\/\/)*(.*)$/ : {
          exec { "cp -f -r $3 $dest_dir":
              unless => $unless,
              path   => "/usr/bin:/usr/sbin:/bin"
          }
      }
      default : { fail("${name} not recordnized.")}     
    } 
  }
  
  define importSQL ($host = "localhost", $db = $oxid::params::db_name, $mysql_user = $oxid::params::db_user, $mysql_password = $oxid::params::db_password, $options = undef, $dump_options = "--add-drop-table --allow-keywords --skip-extended-insert --hex-blob --default-character-set=latin1", $unless = undef) {
    case $name {
      /^(https*|scp|file):(\/\/)*(.*\.tar\.gz|.*\.zip|.*\.gz|.*\.phar)$/ : {
        $tmp_dir = inline_template('<%= Dir.mktmpdir %>')        
        
        importData{$name: dest_dir => $tmp_dir, tmp_dir => $tmp_dir, options => $options, unless => $unless} ->
        
        exec { "mysql import file ${name}":
		      command => "sh -c 'for file in ${tmp_dir}/*.sql; do mysql -h ${host} -u${mysql_user} -p${mysql_password} ${db} < \$file ; done'",
		      unless => $unless,
		      path   => "/usr/bin:/usr/sbin:/bin"
		    } ->
		    
		    exec { "${name}-remove-sql-tmp-files":
              command => "rm -f -r ${tmp_dir}",
              unless => $unless,
              path   => "/usr/bin:/usr/sbin:/bin"
          }
      }
      
      /^ssh:\/\/(.*):mysql:\/\/(.*)\/\?username=(.*)&password=(.*)/ : {
        if $options != undef {
          $option_str = join($options, ' ')
        } else {
          $option_str = ""
        }
      
        $command = "ssh ${option_str} '$1' mysqldump ${dump_options} -u '$3' --password='$4' '$2' | mysql -u '${mysql_user}' --password='${mysql_password}' -D '${db}'"
          
        exec { $command:
          path   => "/usr/bin:/usr/sbin:/bin",
          unless => $unless
        }
      }
      

      /^(file):(\/\/)*(.*\.sql)$/ : {  
        exec { "mysql import file $3":
          command => "mysql -h ${host} -u${mysql_user} -p${mysql_password} ${db} < $3",
          unless => $unless,
          path   => "/usr/bin:/usr/sbin:/bin"
        }
      }      
      
      /(.*\.sql)$/ : {  
        exec { "mysql import file $1":
          command => "mysql -h ${host} -u${mysql_user} -p${mysql_password} ${db} < $1",
          unless => $unless,
          path   => "/usr/bin:/usr/sbin:/bin"
        }
      } 
        
      default : { fail("${name} not recordnized.")} 
    }    
  }
  
  define unpack($destPath, $timeout = 0, $unless = undef) {
    $module_path = get_module_path('oxid')
      
    case $name {
      /^(.*\.phar$)/ : {                    
                    exec { "unphar ${name}":
                      command => "php -f ${module_path}/functions/oxid/phar-extract.php '$1' '${destDir}'", 
                      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
                      unless => $unless,
                      timeout => $timeout
                    }
                  }
      /^(.*\.zip$)/ : {                    
                    exec { "unzip ${name}":
                      command => "unzip -d '${destPath}' -o --qq '$1'",
                      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
                      unless => $unless,
                      timeout => $timeout
                    }
                  }                 
      /^(.*\.tar.gz$)/ : {                    
                    exec { "untar/gz ${name}":
                      command => "tar -C '${destPath}' -zxf '$1'",
                      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
                      unless => $unless,
                      timeout => $timeout
                    }
                  } 
      /^(.*\.gz$)/ : {
                    $filename = inline_template("<%= File.basename(@name).chomp('.gz') %>")                                        
                    exec { "gunzip ${name}":                      
                      command => "gunzip -c '$1' > '${$destPath}/${filename}'",
                      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
                      unless => $unless,
                      timeout => $timeout
                    }
                  }                                                      
       default: { 
        fail("Unrecognized schema: $name") 
        }                  
    }
  }
 
  define install_package($shop_dir, $sql_scripts = undef, $ensure = "active", $host = "localhost", $port = $oxid::params::db_port, $db = $oxid::params::db_name, $user = $oxid::params::db_user, $password = $oxid::params::db_password) {
    $tmp_dir = inline_template('<%= Dir.mktmpdir %>')
    
    unpack{ $name: 
      destPath => $tmp_dir 
    }
    
    $exist = inline_template('<%= File.exists?(File.join(@tmp_dir, "copy_this")) %>')
    
    if($exist == "true") {
      exec { "cp -R -f ${tmp_dir}/copy_this/* ${shop_dir}": 
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        before => Exec["rm -r -f ${tmp_dir}"],
        require => Unpack[$name]     
      }
    } else {
      exec { "cp -R -f ${tmp_dir}/* ${shop_dir}": 
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        before => Exec["rm -r -f ${tmp_dir}"],
        require => Unpack[$name]       
      }
    }
    
    /*if($sql_scripts != undef) {
         $sql_files = split(inline_template("<%= @sql_scripts.each {|f| File.join(@tmp_dir, f) }.join(',') %>"), ',')
         
         oxid::mysql::server::execFile{$sql_files:       
		        host => $host,
		        port => $port,
		        db => $db,
		        user => $user, 
		        password => $password,
		        before => Exec["rm -r -f * ${tmp_dir}"]
	      }
    }*/
    
    exec { "rm -r -f ${tmp_dir}": 
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"     
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
    
    exec { "${name}-oxid-module '${cmd}'":        
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
  
  define update($shop_dir, $update_package, $changed_full = false, $run_cli = false, $run_cli_content= undef) {
    $filename = inline_template('<%= File.basename(@update_package) %>')

    $cmds = ["cp -R -f updateApp/ \"${shop_dir}/\"", "cp -R -f copy_this/* \"${shop_dir}/\""]     
     
    exec { "unzip '${update_package}' -d '${filename}'":        
        cwd => "${oxid::common::params::tmp_dir}",
        path   => "/usr/bin:/usr/sbin:/bin",
        unless => "test -d '${oxid::common::params::tmp_dir}/${filename}'",
        timeout => 120,
        require => Package['unzip']
     } ->
     
      exec { $cmds:        
        path   => "/usr/bin:/usr/sbin:/bin",
        cwd => "${oxid::common::params::tmp_dir}/${filename}"
     } 
          
     if $run_cli {
         if $run_cli_content != undef {
           $expect_filename = "${oxid::common::params::tmp_dir}/${filename}/updateApp/expect_run.cli"
           
           file { "${expect_filename}":
              owner   => root,
              group   => root,
              mode    => 744,
              content => $run_cli_content,
              require => [Exec["unzip '${update_package}' -d '${filename}'"], Exec[$cmds]]
          } ->
            exec { ["expect -f '${expect_filename}'"] :
              path   => "/usr/bin:/usr/sbin:/bin",      
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
    $module_path = get_module_path('oxid')
    $_exists = inline_template("<%= File.exists?('${shop_dir}/bin/cron.php') %>")
    if ($_exists == "true") {
        $updateview_template = "$module_path/templates/oxid/updateviews-5.php.erb"
        /*$updateview_command= "php -r 'if ( !function_exists( \"isAdmin\" )) { function isAdmin() { return true; } } function getShopBasePath() { return \"$shop_dir/\"; } require_once getShopBasePath() . \"modules/functions.php\"; require_once getShopBasePath() . \"core/oxfunctions.php\"; require_once getShopBasePath() . \"core/oxdb.php\"; \$myConfig = oxRegistry::getConfig(); oxDb::getInstance()->updateViews(); \$myConfig->pageClose();'"*/
    } else {
        $updateview_template = "$module_path/templates/oxid/updateviews-448.php.erb"
        /*$updateview_command = "php -r 'if ( !function_exists( \"isAdmin\" )) { function isAdmin() { return true; } } function getShopBasePath() { return \"$shop_dir/\"; } require_once getShopBasePath().\"core/oxfunctions.php\"; require_once getShopBasePath().\"core/oxsupercfg.php\"; require_once getShopBasePath().\"core/oxdb.php\"; oxDb::getInstance()->updateViews(); exit(0);'"*/
    }
    
    exec { "oxid-check-owner ${shop_dir}": 
      command => "chown -R ${owner}:${group} ${shop_dir} & chmod -R ug+rw ${shop_dir}", 
      path => "/usr/bin:/usr/sbin:/bin"
    } ->
     
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
      mode => "ug+rw"
    } -> 

    file { "${shop_dir}/setup":
      ensure => 'absent',
      force => true
    } ->
    
    file { "${shop_dir}/updateApp":
      ensure => 'absent',
      force => true
    } ->
    
    exec { "oxid-check-owner ${compile_dir}": 
      command => "chown -R ${owner}:${group} ${compile_dir} & chmod -R ug+rw ${compile_dir}", 
      path => "/usr/bin:/usr/sbin:/bin"
    } ->
    
     
    
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
     
	  /*exec {"oxid-updateviews-$shop_dir}":
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        command => "php -r 'function getShopBasePath() { return \"$shop_dir/\"; } function isAdmin() { return true; } require_once getShopBasePath().\"core/oxfunctions.php\"; require_once getShopBasePath().\"core/oxsupercfg.php\"; require_once getShopBasePath().\"core/oxdb.php\"; oxDb::getInstance()->updateViews(); exit(0);'"
    }*/   
    
    file { "${compile_dir}/_updateview.php":
            ensure => 'present',
            mode => "0755",
            owner => $owner,
            group => $group,
            content => template($updateview_template)
    } ->
      
    exec {"oxid-updateviews-$shop_dir}":
        path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
        command => "php -f '${compile_dir}/_updateview.php'"
    } ->
    
    exec { "rm -r -f ${compile_dir}/*":
        path   => "/usr/bin:/usr/sbin:/bin"
    }
}