# Provisioning a new Oxid Community Edition Shop base on the current Oxid download.
#
# - Installs a MySQL Server
# - Installs PHP
# - Installs Apache Web Server
# - Installs Oxid with demodata
# - Setting some options in the oxshop table.
#
oxid::repository::config::wget { "oxidce": url => "http://download.oxid-esales.com/ce" }

class { 'oxid::mysql::server::install': password => "secret" }

class { 'oxid::php::install': }

class { 'oxid::apache::install':
  servername => $hostname,
  docroot    => "/srv/www/oxid"
}

class { oxid:
  source              => {
    "index.php" => "OXID_ESHOP_CE_CURRENT.zip"            #   Using a hash to link a source file input to a target file output. Available for wget repositories.
  }
  ,
  repository          => "oxidce",
  shop_dir            => "/srv/www/oxid",
  compile_dir         => "/srv/www/oxid/tmp",
  db_host             => "localhost",
  db_name             => "oxid",
  db_user             => "oxid",
  db_password         => "oxid",
  shop_ssl_url        => "https://${hostname}",
  admin_ssl_url       => "https://${hostname}/admin",
  extra_db_setup_sqls => ["setup/sql/demodata.sql"]
}

oxid::shopConfig { 'oxid':
  host     => "localhost",
  db       => "oxid",
  user     => "oxid",
  password => "oxid",
  configs  => {
    "oxtitleprefix" => "Puppet Oxid Example",
    "oxtitlesuffix" => "Current CE Shop",
    "oxinfoemail"   => "info@example.com",
    "oxorderemail"  => "info@example.com",
    "oxowneremail"  => "info@example.com",
  }
}