include oxid::params

define oxid::repository::config::file ($root = "") {

  if defined(Oxid::Update) {
    Oxid::Update <| |> -> Oxid::Module[$name]
  }

  $oxid::params::repository_configs["${name}"] = {
    'type'      => 'oxid::repository::file',
    'directory' => $root
  }
}