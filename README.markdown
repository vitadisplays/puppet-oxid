# oxid

This puppet module setups a oxid shop including mysql server, apache and php.
For the oxid PE/EE Editions special additional classes oxid::php::zendguardloader, to setup Zend Guard, is included.
With the oxid::repository::get definition, sources from a local or http/https location can be used to get e.g. Zend Guard or oxid binaries/sources.
Also some usefully definitions for remote Data and SQL acquisitions of existing shop is included.
For update paths, the oxid::update definition allows you to make an unattended update.  

## Repositories
Several repositories locations can be configured to get thidparty sources.
At the moment local and wget repositories types are supported.
After that you can e.g. use class oxid with parameter repository and source(only basename) to get required archive.
For your environment you can download the oxid archives by your self and provide them via an http (wget type) or a puppet master(file type and puppet:// URI).
  
### oxid::repository::config::file
	oxid::repository::config::file{ 'oxidee': root => ''}
	
	Configure a local repository named 'oxidee' to the root directory.
	 
### oxid::repository::config::wget
	oxid::repository::config::wget { 'oxid':
  		directory  => undef,
  		url		   => "http://example.com/oxid",
  		user       => undef,
  		password   => undef,
  		timeout    => 900,
  		verbose    => false,
  		redownload => false
  	}
  	
  	Configure a remote repository named 'oxid' to the root URL http://example.com/oxid.
  	
## Mysql
 
## Apache
 
## PHP
 
## Oxid Setup
 
## Remote Utils
 
## Oxid Updates
 
## Simple Oxid CE Setup Example
This install all needed components for a single server with current oxid ce version and with no UTF8 mode.
If you don't want the demo data, please remove extra_db_setup_sqls paramter from class oxid.

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