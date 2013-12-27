include oxid::params

define oxid::repository::unpack ($repository, $source = undef, $destination, $timeout = 0) {
  $mysource = $source ? {
    undef   => $name,
    default => $source
  }

  if is_hash($mysource) {
    $keys = keys($source)

    if (count($keys) != 1) {
      fail("Only one Key/Value Pair allowed.")
    }

    $_source = $source[$keys[0]]
  } else {
    $_source = $mysource
  }
  
  $repo_config = $oxid::params::repository_configs["${repository}"]
  $repo_dir = $repo_config['directory']

  $file = inline_template("<%= File.join(@repo_dir, @_source) %>")

  ::oxid::unpack { $name:
    source      => $file,
    destination => $destination,
    timeout     => $timeout
  }
}