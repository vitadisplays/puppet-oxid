include oxid::params

define oxid::repository::config::wget (
  $directory  = undef,
  $url,
  $user       = undef,
  $password   = undef,
  $timeout    = 900,
  $verbose    = false,
  $redownload = false) {
  $tmp_dir = $oxid::params::tmp_dir
  $repo_dir = $directory ? {
    undef   => inline_template("<%= File.join(@tmp_dir, 'repository', @name) %>"),
    default => $directory
  }

  $oxid::params::repository_configs["${name}"] = {
    'type'      => "oxid::repository::wget",
    "directory" => $repo_dir,
    "url"       => $url,
    "user"      => $user,
    "password"  => $password,
    "timeout"   => $timeout,
    "verbose"   => $verbose,
    "redownload"   => $redownload
  }
}