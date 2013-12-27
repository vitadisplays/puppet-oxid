include oxid::params

define oxid::repository::get ($repository, $source) {
  $config = $oxid::params::repository_configs["${repository}"]
  $directory = $config['directory']

  if $directory != undef and !defined(Exec["mkdir -p '${directory}'"]) {
    exec { "mkdir -p '${directory}'":
      path   => $oxid::params::path,
      unless => "test -d '${directory}'"
    }
  } 
  
  ensure_resource($config['type'], $source, {
    'configuration' => $config,
    'source'        => $source,
    'require'       => $config['directory'] ? {
      undef   => undef,
      default => Exec["mkdir -p '${directory}'"]
    } }
  )
}