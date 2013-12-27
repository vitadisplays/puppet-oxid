define oxid::utf8Update (
  $shop_dir    = $oxid::params::shop_dir,
  $compile_dir = $oxid::params::compile_dir,
  $shop_url    = $oxid::params::shop_url,
  $db_host     = $oxid::params::db_host,
  $db_name     = $oxid::params::db_name,
  $db_user     = $oxid::params::db_user,
  $db_password = $oxid::params::db_password,
  $repository  = $oxid::params::default_repository,
  $source,
  $old_charset = "latin1") {
  $mysource = $source ? {
    undef   => $name,
    default => $source
  }

  $is_utf = inline_template("<%= File.readlines(File.join(@shop_dir, 'config.inc.php')).grep(/\$this->iUtfMode[ ]*=[ ]*'1'.*/) %>")

  if (!$is_utf) {
    $filename = inline_template('<%= File.basename(@mysource) %>')

    oxid::repository::get { "get ${mysource}":
      source     => $mysource,
      repository => $repository
    } ->
    oxid::repository::unpack { "${name}: ${mysource}":
      repository  => $repository,
      source      => $mysource,
      destination => $shop_dir
    } ->
    replace { "${shop_dir}/utf8_*.sql":
      file        => inline_template('<%= Dir.glob(@shop_dir + "/utf8_*.sql") %>'),
      pattern     => "_NAME_OF_DB_",
      replacement => $db_name
    } ->
    oxid::mysql::execFile { "run utf8 sql statements":
      source   => inline_template('<%= Dir.glob(@shop_dir + "/utf8_*.sql") %>'),
      host     => $db_host,
      db       => $db_name,
      user     => $db_user,
      password => $db_password
    } ->
    exec { "${name} file clean ${compile_dir}":
      command => "find '${compile_dir}' ! -name .htaccess -type f -delete",
      path    => $oxid::params::path
    } -> replace { "set utf8 mode":
      file        => "${shop_dir}/confog.inc.php",
      pattern     => "\$this->iUtfMode[ ]*=[ ]*.*;",
      replacement => "\$this->iUtfMode = '1';"
    }
  } else {
    fail("Already UTF-8 mode activated.")
  }
}