include oxid::params

define oxid::repository::config::file ($root = "") {
  $oxid::params::repository_configs["${name}"] = {
    'type'      => 'oxid::repository::file',
    'directory' => $root
  }
}