# Provisioning a Oxid Enterprise Edition Shop base on an existing remote shop and do an upgrade to 5.1.x.
#
# - Installs a MySQL Server
# - Installs PHP
# - Installs Apache Web Server
# - Installs Zend Guard
# - Installs Oxid EE 4.4.8
# - Upgrade to 5.1.x
# - Setting some option in the oxshop table.
#

#Key file to act with remote host
$keyfile = "/vagrant_data/vitadisplays_rsa"

# Common configurations
$configurations = loadyaml("/vagrant_data/oxid-config.yml")

# Host dependent configurations
$configurations['sShopURL'] = "http://${hostname}"
$configurations['sSSLShopURL'] = "https://${hostname}"
$configurations['sAdminSSLURL'] = "https://${hostname}/admin"

# Local repository
/*oxid::repository::config::file { "oxidee": root => $configurations['oxideeRepository'] } ->*/

# Remote repository
oxid::repository::config::wget { "oxidee": url => $configurations['oxideeRepository'] } ->

# MySQL Server install
class { 'oxid::mysql::server::install':
  password => $configurations['mysql_password']
}

# PHP install
class { 'oxid::php::install':
}

# Zend Guard install
class { 'oxid::php::zendguardloader':
}

# Apache Server install
class { 'oxid::apache::install':
  docroot => $configurations['sShopDir']
}

# Oxid Install and updates
class { oxid448: configurations => $configurations , keyfile => $keyfile} ->
class { oxid448To465: configurations => $configurations } ->
class { oxid465To500: configurations => $configurations } ->
class { oxid500To51x: configurations => $configurations } ->
# Alter Tables statements, to add columns not included in the update path. May be changed or comment out for your requirements!
mysql_query { 
  "ALTER TABLE oxcategories ADD COLUMN OXTHUMB_1 VARCHAR(128) NOT NULL DEFAULT '' AFTER OXTHUMB;ALTER TABLE oxcategories ADD COLUMN OXTHUMB_2 VARCHAR(128) NOT NULL DEFAULT '' AFTER OXTHUMB_1; ALTER TABLE oxcategories ADD COLUMN OXTHUMB_3 VARCHAR(128) NOT NULL DEFAULT '' AFTER OXTHUMB_2;
 ALTER TABLE oxactions ADD COLUMN OXPIC_1 VARCHAR(128) NOT NULL DEFAULT '' AFTER OXPIC; ALTER TABLE oxactions ADD COLUMN OXPIC_2 VARCHAR(128) NOT NULL DEFAULT '' AFTER OXPIC_1;ALTER TABLE oxactions ADD COLUMN OXPIC_3 VARCHAR(128) NOT NULL DEFAULT '' AFTER OXPIC_2;
  ALTER TABLE oxactions ADD COLUMN OXLINK_1 VARCHAR(128) NOT NULL DEFAULT '' AFTER OXLINK; ALTER TABLE oxactions ADD COLUMN OXLINK_2 VARCHAR(128) NOT NULL DEFAULT '' AFTER OXLINK_1;ALTER TABLE oxactions ADD COLUMN OXLINK_3 VARCHAR(128) NOT NULL DEFAULT '' AFTER OXLINK_2;"
  :
  db_host     => $configurations['dbHost'],
  db_name       => $configurations['dbName'],
  db_user     => $configurations['dbUser'],
  db_password => $configurations['dbPwd'],
}

# Oxid EE 4.4.8 install Class with remote data.
# Dump tables will be fetch dynamically from the remote database by a sql statement, excluding all views. 
# Remove also all Modules from Database, by removing aModule oxvarname.
class oxid448 ($configurations, $keyfile) {
  
  class { oxid:
    source         => "OXID_ESHOP_EE_4.4.8_34028_for_PHP5.3.zip",
    repository     => "oxidee",
    shop_dir       => $configurations['sShopDir'],
    compile_dir    => $configurations['sCompileDir'],
    db_host        => $configurations['dbHost'],
    db_name        => $configurations['dbName'],
    db_user        => $configurations['dbUser'],
    db_password    => $configurations['dbPwd'],
    shop_ssl_url   => $configurations['sSSLShopURL'],
    admin_ssl_url  => $configurations['sAdminSSLURL'],
    purge          => true,
  }
  
  oxid::shopConfig { $name:
    shopid   => 1,
    host     => $configurations['dbHost'],
    port     => $configurations['mysql_port'],
    db       => $configurations['dbName'],
    user     => $configurations['dbUser'],
    password => $configurations['dbPwd'],
    configs  => {
      "oxtitleprefix" => "",
      "oxtitlesuffix" => "VITAdisplays SHOP",
      "oxinfoemail"   => "technik@vitadisplays.com",
      "oxorderemail"  => "technik@vitadisplays.com",
      "oxowneremail"  => "technik@vitadisplays.com",
    }
  }  

  file { $keyfile:
    ensure => present,
    mode   => 0600
  } ->
  oxid::sshFetchRemoteData { "root@shop1.vitadisplays.com":
    shop_dir   => $configurations['sShopDir'],
    remote_dir => $configurations['remotePath'],
    keyfile    => $keyfile
  } ->
  oxid::sshFetchRemoteSQL { "root@shop1.vitadisplays.com":
    db_name            => $configurations['DBName'],
    db_user            => $configurations['DBUser'],
    db_password        => $configurations['DBPwd'],
    keyfile            => $keyfile,
    remote_db_name     => $configurations['remoteDBName'],
    remote_db_user     => $configurations['remoteDBUser'],
    remote_db_password => $configurations['remoteDBPwd'],
    dump_tables        => "$(mysql --user='${configurations['remoteDBUser']}' --password='${configurations['remoteDBPwd']}' -B -N -e \"Select TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA = '\\''${configurations
      ['remoteDBName']}'\\'' AND TABLE_TYPE != '\\''VIEW'\\''\" | grep -v Tables_in | xargs)",
    dump_options       => $oxid::params::default_remote_dump_options_latin1
  }

  oxid::mysql::execSQL { "DELETE FROM oxconfig WHERE oxvarname IN ('aModules');":
    host     => $configurations['dbHost'],
    db       => $configurations['dbName'],
    user     => $configurations['dbUser'],
    password => $configurations['dbPwd'],
    require  => Class[oxid]
  }
}

# Upgrade from 4.4.8 to 4.6.5
# Simple CLI upgrade, with SQL hack
class oxid448To465 ($configurations) {
  # remove some contents to run succesfully 34028.sql in UPDATE_OXID_ESHOP_EE_V.4.4.8_34028_TO_V.4.6.5_49955_for_PHP5.3.zip. Also
  # change 34028.sql last statement (user oxshops.oxid except 1 as oxshopid, if you have several shops)
  oxid::mysql::execSQL { "DELETE FROM oxcontents WHERE oxloadid IN ('oxrighttocancellegend2')":
    host     => $configurations['dbHost'],
    db       => $configurations['dbName'],
    user     => $configurations['dbUser'],
    password => $configurations['dbPwd'],
  } ->
  oxid::update { $name:
    shop_dir      => $configurations['sShopDir'],
    compile_dir   => $configurations['sCompileDir'],
    db_host       => $configurations['dbHost'],
    db_name       => $configurations['dbName'],
    db_user       => $configurations['dbUser'],
    db_password   => $configurations['dbPwd'],
    shop_ssl_url  => $configurations['sSSLShopURL'],
    admin_ssl_url => $configurations['sAdminSSLURL'],
    source        => "UPDATE_OXID_ESHOP_EE_V.4.4.8_34028_TO_V.4.6.5_49955_for_PHP5.3.zip",
    repository    => "oxidee",
    answers       => ["2", "1", "1"],
    fail_on_error => true
  }
}

# Upgrade from 4.6.5 to 5.0.0
# Advance CLI upgrade with moving shop and reinstall new one, see http://wiki.oxidforge.org/Tutorials/Update_from_4.6.5_to_4.7.0_or_5.0.0
class oxid465To500 ($configurations) {
  $shop_dir = $configurations['sShopDir']
  $bakupdir = "${configurations['sShopDir']}_bak"

  exec { "rm -r -f ${bakupdir}":
    path   => "/usr/bin:/usr/sbin:/bin",
    onlyif => "test -d ${bakupdir}"
  } ->
  exec { "mv ${configurations['sShopDir']} ${bakupdir}": path => "/usr/bin:/usr/sbin:/bin" } ->
  oxid::repository::get { $name:
    repository => "oxidee",
    source     => "OXID_ESHOP_EE_5.0.0_51243_for_PHP5.3.zip"
  } ->
  oxid::repository::unpack { $name:
    repository  => "oxidee",
    source      => "OXID_ESHOP_EE_5.0.0_51243_for_PHP5.3.zip",
    destination => $configurations['sShopDir']
  } ->
  oxid::fileCheck { "${name}-unpack":
    shop_dir    => $configurations['sShopDir'],
    compile_dir => $configurations['sCompileDir']
  } ->
  oxid::mysql::execSQL { "ALTER TABLE oxnewssubscribed DROP OXTIMESTAMP":
    host     => $configurations['dbHost'],
    db       => $configurations['dbName'],
    user     => $configurations['dbUser'],
    password => $configurations['dbPwd'],
  } ->
  exec { "cp -r -f ${bakupdir}/out/pictures/* ${configurations['sShopDir']}/out/pictures/":
    path    => "/usr/bin:/usr/sbin:/bin",
    timeout => 0
  } ->
  # make an upgrade in sql mode without modyfing themes etc. Have problems in cli mode.  
  oxid::update { $name:
    run_method      => "sql",
    shop_dir      => $configurations['sShopDir'],
    compile_dir   => $configurations['sCompileDir'],
    db_host       => $configurations['dbHost'],
    db_name       => $configurations['dbName'],
    db_user       => $configurations['dbUser'],
    db_password   => $configurations['dbPwd'],
    shop_ssl_url  => $configurations['sSSLShopURL'],
    admin_ssl_url => $configurations['sAdminSSLURL'],
    source        => "UPGRADE_OXID_ESHOP_EE_V.4.6.5_49955_TO_V.5.0.0_51243.zip",
    repository    => "oxidee"
  }
}

# Upgrade from 5.0.0 to 5.1.x
# Simple SQL upgrade with azure theme activating.
class oxid500To51x ($configurations) {
  oxid::update { $name:
    run_method    => "sql",
    shop_dir      => $configurations['sShopDir'],
    compile_dir   => $configurations['sCompileDir'],
    db_host       => $configurations['dbHost'],
    db_name       => $configurations['dbName'],
    db_user       => $configurations['dbUser'],
    db_password   => $configurations['dbPwd'],
    shop_ssl_url  => $configurations['sSSLShopURL'],
    admin_ssl_url => $configurations['sAdminSSLURL'],
    source        => "UPDATE_OXID_ESHOP_EE_V.5.0.0_TO_V.5.1.1_for_PHP_5.3.zip",
    repository    => "oxidee",
    answers       => ["2"]
  } ->
  oxid::theme { 'azure':
    shopid         => 1,
    shop_dir       => $configurations['sShopDir'],
    compile_dir    => $configurations['sCompileDir'],
    configurations => {
      'confbools' => {
        'bl_showOpenId' => false
      }
    }
  }
}
