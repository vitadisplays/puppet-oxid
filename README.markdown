# oxid

This puppet module setups an oxid shop including mysql server, apache and php.

## Features
	- MySQL Server installation/setup
	- PHP installation/setup
	- Apache installation/setup
	- Zend Guard installation/setup
		For the oxid PE/EE Editions special classes, like oxid::php::zendguardloader to setup Zend Guard, are included.
	- Repository stuff, to handle sources from local or remote locations in a same way. 
	- Remote stuff, to download oxid data and sql dump.
	- Oxid Shop installation/setup. 
		Supported Versions: 4.5, 4.6, 4.7, 4.8, 5.0, 5.1 and also legacy version 4.4.8
	- Oxid Theme installation/setup
	- Oxid Module installation/setup
	- Common configuration of oxconfig and oxshop
	- File checks, see http://wiki.oxidforge.org/Installation#Files_.26_Folder_Permission_Setup for details.
	- View Updates for oxid EE, to work correctly.
	- Oxid Shop unattended update/upgrade
		This was the primary reason for developing this module, to get the possibility to update from oxid EE 4.4.8 to 5.1.1.

## Repositories
Several repositories locations can be configured to get third-party archives.
At the moment local and wget repositories types are supported.
E.g. use class oxid with parameter repository and source(only basename) to get required archive.
For your environment you can download the oxid archives by your self and provide them via a local file directory, a http server or a puppet master setup in conjunction with a 'puppet://something' URI.
  
### oxid::repository::config::file
```puppet
	oxid::repository::config::file{ 'oxidee': root => ''}
```	
	Configure a local repository named 'oxidee' to the root directory.
	 
### oxid::repository::config::wget
```puppet
	oxid::repository::config::wget { 'oxid':
  		directory  => undef,
  		url		   => "http://example.com/oxid",
  		user       => undef,
  		password   => undef,
  		timeout    => 900,
  		verbose    => false,
  		redownload => false
  	}
```  	
  	Configure a remote repository named 'oxid' to the root URL http://example.com/oxid.  	
  	 
## Mysql
Installs and setups a mysql server. This is optional, you can use a remote or install a custom MySQL sever instance.
A password is required. If you do not specify any override_options, the default override options will be calculated, see class oxid::mysql::server::params.
The example shows you a configuration with 2GB system memory. For more information see https://forge.puppetlabs.com/puppetlabs/mysql.

```puppet
 class {
    'oxid::mysql::server::install': 
    password => "secret",
    override_options => {
	    'mysqld' => {
	      'max_connections'   => 100,
	      'table_cache'       => 12800,
	      'key_buffer'        => "256M",
	      'join_buffer_size'  => "8M",
	      'query_cache_size'  => "64M",
	      'query_cache_limit' => "64M"
	    }
	 }  
  }
```
  
## Apache
Installs and setups an Apache server instance. This is optional, you can use a custom Apache sever instance/setup.
For more information see https://forge.puppetlabs.com/puppetlabs/apache.
 
```puppet
	oxid::apache::install { "apache":
	  docroot           => "/srv/www/oxid",
	  servername        => "myhostname",
	  vhost_name        => '*',
	  default_mods      => true,
	  default_vhost     => false,
	  default_ssl_vhost => false,
	  ip                => "127.0.0.1",
	  ssl               => true,
	  ssl_cert          => undef,
	  ssl_key           => undef
	}
``` 
## PHP
Installs and setups PHP. This is optional, you can use a custom PHP setup.
Custom settings are provided by the class oxid::php::params to fit oxid requirements.
For more information see https://forge.puppetlabs.com/nodes/php.

```puppet 
class { 'oxid::php::install':  
	  $ensure   = 'installed',
	  $package  = 'libapache2-mod-php5',
	  $provider = undev,
	  $inifile  = '/etc/php5/apache2/php.ini',
	  $settings = $settings = {
	    set => {
	      'PHP/short_open_tag'      => 'Off',
	      'PHP/asp_tags'            => 'Off',
	      'PHP/expose_php'          => 'Off',
	      'PHP/memory_limit'        => '128M',
	      'PHP/display_errors'      => 'Off',
	      'PHP/log_errors'          => 'On',
	      'PHP/post_max_size'       => '500M',
	      'PHP/upload_max_filesize' => '500M',
	      'PHP/max_execution_time'  => 600,
	      'PHP/allow_url_include'   => 'Off',
	      'PHP/allow_url_fopen'     => 'On',
	      'PHP/register_globals'    => 'Off',
	      'PHP/error_log'           => 'syslog',
	      'PHP/output_buffering'    => 4096,
	      'PHP/output_handler'      => 'Off',
	      'PHP/session.auto_start'  => 'Off',
	      'Date/date.timezone'      => 'UTC'
	    }
	  }
}
```

### Zend Guard
The class oxid::php::zendguardloader will add Zend Guard to the apache php module.
This class is configured with the zend repository by default.

## Oxid Setup
The class oxid setups a oxid shop. Requires an Apache instance, a PHP installation and a MySQL server instance to work.

```puppet 
oxid { "oxid":
  source			  => { "index.php" => "OXID_ESHOP_CE_CURRENT.zip"},
  repository          => "oxidce",
  purge               => true,
  shop_dir            => "/srv/www/oxid",
  compile_dir         => "/srv/www/oxid/tmp",
  db_type             => "mysql",
  db_host             => "localhost",
  db_name             => "oxid",
  db_user             => "oxid"
  db_password         => "oxid",
  shop_url            => "http://myhostname",
  shop_ssl_url        => "https://myhostname",
  admin_ssl_url       => "https://myhostname/admin",
  utf8_mode           => 0,
  sql_charset         => "latin1",
  mysql_user          => "root",
  mysql_password      => "oxid",
  rewrite_base        => "/",
  config_content      => undef,
  htaccess_content    => undef,
  config_source       => undef,
  htaccess_source     => undef,
  config_extra_replacements   => {},
  htaccess_extra_replacements => {},
  db_setup_sql        => "setup/sql/database.sql",
  extra_db_setup_sqls => undef,
  owner               => "www-data",
  group               => "www-data"
}
```

### Setup Configuration
The file config.inc.php and .htaccess file will be configure, by token replacements in conjunction with the defined parameters or directly by source contents.
 
### Parameters
	- repository					The repository to get from
	- source						The location of the setup archive in the defined repository. For output mapping use a hash, like { "index.php" => "OXID_ESHOP_CE_CURRENT.zip"}. This will download index.php to download file OXID_ESHOP_CE_CURRENT.zip. Helpfully to download from oxid default location.
	- purge							If true, deletes the shop dir.
	- shop_dir						The oxid shop directroy
	- compile_dir					The oxid compile directroy
	- db_type						Default is mysql and is only supported type.
	- db_host						Oxid database host
	- db_name						Oxid database name
	- db_user						Oxid database user
	- db_password					Oxid database password
	- shop_url						Oxid shop url
	- shop_ssl_url					Oxid shop ssl url
	- admin_ssl_url					Oxid admin ssl url
	- sql_charset					The chaset of the sql files. Default latin1.
	- mysql_user					MySQL User to prepare database
	- mysql_password				MySQL password
	- rewrite_base					Rewrite Base in the .htaccess file
	- config_content				Your own oxyid configuration content
	- htaccess_content				Your own htaccess configuration content	
	- config_source					Your own oxid configuration source
	- htaccess_source				Your own oxid htaccess source
	- config_extra_replacements		Extra replacements for oxid configuration. Example: {"\$this->sTheme[ ]*=[ ]*.*;" => "\$this->sTheme = 'basic';" }
	- htaccess_extra_replacements	Extra replacements for htaccess
	- db_setup_sql					The setup file to execute. By default "setup/sql/database.sql"
	- extra_db_setup_sqls			Extra setup files to execute. e.g. ["setup/sql/demodata.sql"] will also install demo data. For Ordering use Oxid::Mysql::ExecFile["source1"] -> Oxid::Mysql::ExecFile["source2"] 
	- owner							The owner of the directories
	- group							The group of the directories
	  
### File check
A file check is done by default, to change owner, group and permissions of each file or directory.
Removes also setup and updateApp directoryies. The compile directory will be purged.
See http://wiki.oxidforge.org/Installation#Files_.26_Folder_Permission_Setup for details.

### Update views
An update view command will be done by default to create all necessary Views in the database.
This is needed for e.g. Oxid Enterprise Edition to work correctly.
    
## Remote Utils
Some helpfull utils to handle with existing shops.

### oxid::sshFetchRemoteData
Fetch via ssh/rsync shop data files.
The backup directory allows you to use the archive files without downloading them twice.
Use purge => true to purge the backuped file.
Allowed compression for the archive: gzip, bzip2 and none.

This define will recordnize the ordering the oxid class executions.

```puppet 
oxid::sshFetchRemoteData { "root@myhostname":
  shop_dir 					=> "/srv/www/oxid",
  remote_dir				=> "/srv/www/oxid",
  includes    				=> ["out/pictures", "out/media", "out/downloads"]
}
```
  
### oxid::sshFetchRemoteSQL
Fetch via ssh shop sql data and import them to the MySQL Database. 
The backup directory allows you to use the archive files without downloading them twice.
Use purge => true to purge archive file.
Allowed compression for the archive: gzip, bzip2 and none.

Use dump_tables => [] download all tables and views. This example use an advance statement to collect all table names excluding oxadminlog and all views.
In the oxid Enterprise Edition, Views shoul be excluded in the dump. Otherwise you run in some problems.
 
I have prepare two dump_options: $oxid::params::default_remote_dump_options_utf8 and $oxid::params::default_remote_dump_options_latin1.
This allows you creating mysql dumps for utf8 and latin1 charsets.
  
This define will recordnize the ordering the oxid class executions.
  
```puppet 
oxid::sshFetchRemoteSQL { "root@myhostname":
  db_name            => "oxid",
  db_user            => "oxid",
  db_password        => "oxid"
  db_host            => "localhost",
  db_port            => 3306,
  remote_db_name     => "oxid",
  remote_db_user     => "oxid",
  remote_db_password => "oxid",
  remote_db_host     => "localhost",
  remote_db_port     => 3306,
  dump_tables 		 => "$(mysql --user='${configurations['remoteDBUser']}' --password='${configurations['remoteDBPwd']}' -B -N -e \"Select TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '\\''${configurations['remoteDBName']}'\\'' AND TABLE_TYPE != '\\''VIEW'\\'' AND TABLE_NAME NOT IN('\\''oxadminlog'\\'')\" | grep -v Tables_in | xargs)",
  dump_options       = $oxid::params::default_remote_dump_options_utf8
}
```
## Oxid Updates
Updates an existing oxid shop.
Oxid offers update/upgrade packages. These packages have to unpack and some archive directories have to copy to shop directory.
A script have to be executed to run the update process. The update process can not complete without user actions.  
This module offer a solution to complete the update process without user actions. A new unattended run_cli.php script custom UI class defintion will be used, to answer the questions in the update process.
Also you can only run the sql files for update. This is usefully, because sometimes the update process in cli mode does not execute correctly the sql files.
This will also update the config.inc.php and .htaccess file, make a file check and make a view update, if set.

```puppet
oxid::update { "oxid448To465"
  source			  => "UPDATE_OXID_ESHOP_EE_V.4.4.8_34028_TO_V.4.6.5_49955_for_PHP5.3.zip",
  repository          => "oxidee",
  shop_dir            => "/srv/www/oxid",
  compile_dir         => "/srv/www/oxid/tmp",
  db_type             => "mysql",
  db_host             => "localhost",
  db_name             => "oxid",
  db_user             => "oxid"
  db_password         => "oxid",
  shop_url            => "http://myhostname",
  shop_ssl_url        => "https://myhostname",
  admin_ssl_url       => "https://myhostname/admin",
  utf8_mode           => 0,
  sql_charset         => "latin1",
  mysql_user          => "root",
  mysql_password      => "oxid",
  rewrite_base        => "/",
  config_content   	  => undef,
  htaccess_content 	  => undef,
  config_source    	  => undef,
  htaccess_source  	  => undef,
  config_extra_replacements   => {},
  htaccess_extra_replacements => {},
  owner            	  => "www-data",
  group            	  => "www-data",
  copy_this        	  => 'before',
  changed_full     	  => 'after',
  run_method       	  => "cli",
  answers          	  => [],
  fail_on_error    	  => true,
  updateViews      	  => true,
  timeout          	  => 900
}
```
### Parameters
	See class oxid for more parameter details.
	- copy_this        	  before or after update process to copy all files from the copy_this directory to the shop directory. Use none to stop copy.
	- changed_full     	  before or after update process to copy all files from the xhanged_full directory to the shop directory. Use none to stop copy.
 	- run_method       	  cli or sql. In the cli mode the run_cli.php will be executed and in sql mode only the sql files will be imported.
  	- answers          	  Anwser array
  	- fail_on_error    	  Set to true, to ignore failures on cli update process. 
  	- updateViews      	  If true, update all views
	- timeout			  the timeout for the update process.	

### Limitations
	- Updates to UTF8 is not supported by this define! 
	- Attention on utf8_mode changes.
	- Theme updates are not really supported.
	
## oxid::shopConfig
	This define sets new values to oxshop table.

### Parameters:
	- shopid      Shop id of the shop to set new values. Default is 'oxbaseshop'. On EE Version always define this parameter.
	- configs     Hash with Key/Value Pairs, e.g. { 'columname' => 'new value' }
	- host        Database host: Default is "localhost".
	- port        Database port: Default is 3306.
	- db          Database name: Default is "oxid".
	- user        Database user: Default is "oxid".
	- password    Database password: Default is "oxid".

### Simple Oxid CE Setup Example
```puppet
   oxid::shopConfig{'oxid':
      shopid  => 1,
      host => "localhost",
      port => 3306,
      db => "oxid",
      user => "oxid", 
      password => "",
      configs => {
         "oxtitleprefix" => "",
         "oxtitlesuffix" => "My New SHOP",
         "oxinfoemail" => "info@example.com",
         "oxorderemail" => "info@example.com",
         "oxowneremail" => "info@example.com",
      } 
   }
```

##	oxid::oxconfig
The define oxid::oxconfig allows you to configure default values.
Legacy Version of oxid, like 4.4.8, are recordnized. Theme or Module configuration will be converted to default configurations.

### Parameters:
	- ensure              present or absen. Default is present.
	- shopid              Shop id, Used for Enterprise Editions. Default is oxbase.
	- type                default for common parameters, theme for theme parameters and module for module parameters
	- module              empty for common parameters and theme or module id.
	- shop_dir            The oxid shop directroy.
	- configurations      Hash value.

 Structure:
```puppet 
  {
    'confbools' => {                           Boolean values
      'testbool'  => true,                     Key/Value pairs
      'Otherbool' => false                            
    }
    ,
    'confstrs'  => {                           String values
      'teststr'   => "test"                    Key/Value pairs
    }
    ,
    'confarrs'  => {                           Array values
      'testarr'   => ["1", "2"]                Key/Value pairs
    }
    ,
    'confaarrs' => {
      'testaarr'  => {                         Hash values
        "hash"         => {"a" => "b"}         Key/Value pairs
      }
    }
    ,
    'confnum'   => {                           Numeric values
      'testnum'   => 1                         Key/Value pairs
    }
  }
```
	You have not to define all parent keys for using this define. 
	Not all variants have be tested!

##	oxid::theme
The define oxid::theme allows you to install/remove and/or configure oxid themes.
You do need any extra afford, like variblename prefixing "theme::name", on configuration.
Legacy Version of oxid, like 4.4.8, are recordnized. Theme configuration will be converted to default configurations without prefixes.

### Parameters:

	- ensure              present or absen. Default is present.
	- repository          The repository to get from
	- source              The location of the setup archive in the defined repository.
	- shopid              Shop id, Used for Enterprise Editions. Default is oxbase.
	- active              If true, activate theme. Default is true.
	- shop_dir            The oxid shop directroy.
	- compile_dir         The oxid compile directroy
	- configurations      Hash configurations options. See define oxid::oxconfig for more details.
	- user                The owner of the directories
	- group               The group of the directories
	- copy_map            Hash to help unpacking and coping files. Default is undef, that unpack as flat file. Use {'copy_this/'    => '', 'changed_full/' => '' } for oxid default structure.
	- files               Array of files/directories to delete. Only used if ensure => 'absent'.
	- default_theme       Default theme name, to activate, if ensure => 'absent'.

##	oxid::module
The define oxid::module allows you to install and/or configure oxid modules.
You do need any extra afford, like name prefixing "module::name", on configuration.
Legacy Version of oxid, like 4.4.8, are recordnized. Theme configuration will be converted to default configurations without prefixes.

### Parameters:
	- ensure			activated, installed, overwrite, deactivated or purged. 'installed' install the module, but do not
						activate the module, 'activated' does. 'overwrite' is like activated, but overrides class_mapping values. 'deactivated'
						deactivate the module, but do nor remove module files, purged does. Default is activated.
	- repository        The repository to get from.
	- source            The location of the setup archive in the defined repository.
	- shopid            Shop id, Used for Enterprise Editions. Default is oxbase.
	- shop_dir          The oxid shop directroy.
	- compile_dir       The oxid compile directroy
	- configurations    Hash configurations options. See define oxid::oxconfig for more details.
	- class_mapping     Hash for extending oxid classes. Used only for legacy mode. Oxid Version before 4.5.x.
						Single Mapping:
```puppet                         
                         class_mapping => {
                           "classToExtend" => "path1/class1"
                         }

                         Mutiple mapping:
                         class_mapping => {
                           "classToExtend" => ["path1/class1", "path2/class2"]
                         }
```                         
						The define will recordnize the uniqueness of the arrays. Existing class to extend, will be appended with new entries.
						if ensure => overwrite the Existing class to extend will be be overwriten with the define entries. This
						will remove old mapping entries for then given class to extend.
	- user              The owner of the directories
	- group             The group of the directories
	- copy_map          Hash to help unpacking and coping files. Default is undef, that unpack as flat file. Use {'copy_this/'  => '', 'changed_full/' => '' } for oxid default structure.
	- files             Array of files/directories to delete. Only used if ensure => 'absent'.
   	
## Simple Oxid CE Setup Example
This install all needed components for a single server with current oxid ce version and with no UTF8 mode.
If you don't want the demo data, please remove extra_db_setup_sqls parameter from class oxid.

```puppet
  oxid::repository::config::wget{"oxidce": url => "http://download.oxid-esales.com/ce"}
  
  class {
    'oxid::mysql::server::install': 
    password => "oxid"
  }  
  
  class { 'oxid::php::install': 
  }
  
  class { 'oxid::apache::install':
  	 servername => $hostname,
     docroot => "/srv/www/oxid"
  }
  
  class {
     oxid: 
     source => { "index.php" => "OXID_ESHOP_CE_CURRENT.zip"},
     repository => "oxidce",
     shop_dir            => "/srv/www/oxid",
  	 compile_dir         => "/srv/www/oxid/tmp",
  	 db_host             => "localhost",
  	 db_name             => "oxid",
  	 db_user             => "oxid",
  	 db_password         => "oxid",
     shop_ssl_url        => "https://${hostname}",
  	 admin_ssl_url       => "https://${hostname}/admin",
  	 mysql_user          => "root",
     mysql_password      => "oxid",
     extra_db_setup_sqls => ["setup/sql/demodata.sql"]
  }
```

## Examples
Under the folder examples, you find some simple and adavance cases to use this module.
The puppet folder includes the init.pp files for several cases.
Feel free to change it for your own requierments.
 
### Requirements
	- Vitualbox >= 4.2
	- Vagrant >= 1.4.0
	
#### Virtualbox and Vagrant
Virtualbox and Vagrant is used for these examples.
Reaad the comments in Vagrant file, for activating the several examples.
Change config.vm.box, config.vm.hostname, config.vm.box_url and so on for your requirements.
Run vagrant up in your vagrant folder to starting up VM. If no provision was made, run vagrant provision to do this, or use vagrant up --provision.

##### Boxes
I have tested agains the precise64 box from vagrant http://files.vagrantup.com/precise64.box.

Use vagrant box add precise64 http://files.vagrantup.com/precise64.box to install requiered box.

I run into several problems, with the installed vagrant ruby version and augeas.
I resolve the problems by upgrading to ruby 1.9.
I provide a shell that do the job for me. See shell for details.

##### shell
Vagrant runs a shell provisoning (examples/shell/main.sh), to install some requirements:
	- ruby 1.9						augeas problem
	- open3_backport >= 0.0.3		augeas problem
	- puppet >= 3.4.2				current puppet version
	- facter >= 1.7.4				current facter version
	- librarian-puppet-maestrodev	current librarian-puppet-maestrodev to install puppet modules
	- installs current puppet-oxid module from git, including dependencies.	See main.sh for other options.

You can use this script to prepare you own boxes.
If no more needed, comment out config.vm.provision :shell in Vagrant file.

### Current CE
	Installs a current Oxid CE Shop. Binary sources will be loaded from http://download.oxid-esales.com/ce
	Change Vagrant puppet.manifests_path to "../puppet/current_ce/manifest"
	
	Actions:
	- Install MySQL Server
	- Install PHP
	- Install Zend Guard
	- Install Apache
	- Install current oxid CE Shop
	- Set some values in the oxshops table.
		
### Upgrade Oxid EE 4.4.8 to 5.1.1
	Installs a Oxid Shop EE 4.4.8 with sql dump, piciture and media data from a remote host.
	Preapare your own download location for the oxid binaries. See Actions, which binaryies aou have to to provide.
	Change init.pp, if you don#t want a wget repositoy. 
	
	Change Vagrant puppet.manifests_path to "../puppet/upgradeEE448To5.1.x/manifest"
	Change Vagrant config.vm.synced_folder to e.g. "../../../mydata", "/vagrant_data"
	
	Add/Change YAML oxid-config.yml file for your requirements in config.vm.synced_folder. Under examples/puppet/upgradeEE448To5.1.x/yaml you find an example.
	Attention: Because of using a remote oxid instance, used this script with your own risk! Try to use mysql user with only read access.
	Add keyfile to config.vm.synced_folder
		
	Actions:
	- Install MySQL Server
	- Install PHP
	- Install Zend Guard
	- Install Apache
	- Install 4.4.8 with source OXID_ESHOP_EE_4.4.8_34028_for_PHP5.3.zip
	- Fetches picture and media data from remote host
	- Fetches sql dump from remote host
	- Upgrade from 4.4.8 to 4.6.5 with source UPDATE_OXID_ESHOP_EE_V.4.4.8_34028_TO_V.4.6.5_49955_for_PHP5.3.zip
	- Upgrade from 4.6.5 to 5.0.0 with source UPGRADE_OXID_ESHOP_EE_V.4.6.5_49955_TO_V.5.0.0_51243.zip. Some files may be upgraded by you, see init.pp class oxid448To465 for more details.
	- Upgrade from 5.0.0 to 5.1.1 with source UPDATE_OXID_ESHOP_EE_V.5.0.0_TO_V.5.1.1_for_PHP_5.3.zip
	- Activate azure theme	

## Requirements
	- maestrodev/wget 1.3.1
	- camptocamp/augeas 0.0.1
	- puppetlabs/stdlib 4.1.0
	- puppetlabs/apt 1.4.0
	- puppetlabs/concat 1.0.0
	- puppetlabs/mysql 2.1.0
	- nodes/php 0.7.0
	- puppetlabs/apache 0.10.0
	- puppetlabs/concat 1.0.0
	
## Limitations
	This has been tested on Ubuntu Precise.
	Debian Debian Wheezy, CentOS 5.8, and FreeBSD 9.1 should work, because of the used dependencies.

## Todo
	- Setting license information in PE/EE versions
	- unattended utf8 update
	- more testing
	