define replace_all ($file, $replacements) {
  validate_hash($replacements)

  if !defined(Class[oxid::package::utils]) {
    include oxid::package::utils
  }

  $command = join(suffix(prefix(join_keys_to_values(slash_escape_hash($replacements), "/"), "perl -pi -e \"s/"), "/\" '${file}'"), ' && '
  )
  $for_name = join_keys_to_values($replacements, " => ")

  exec { "${name} replace_all ${for_name} in ${file}":
    command => $command,
    path    => $oxid::params::path
  }
}

define replace ($file, $pattern, $replacement) {
  if !defined(Class[oxid::package::utils]) {
    include oxid::package::utils
  }

  $pattern_no_slashes = slash_escape($pattern)
  $replacement_no_slashes = slash_escape($replacement)

  exec { "${name} replace ${pattern} with ${replacement} in ${file}":
    command => "perl -pi -e \"s/$pattern_no_slashes/$replacement_no_slashes/\" '$file'",
    path    => $oxid::params::path
  }
}

define oxid::fileCheck (
  $shop_dir    = $oxid::params::shop_dir,
  $compile_dir = $oxid::params::compile_dir,
  $owner       = $oxid::apache::params::user,
  $group       = $oxid::apache::params::group,
  $refreshonly = false) {
  validate_absolute_path($shop_dir)
  validate_absolute_path($compile_dir)

  exec { "${name} file permissions check ${shop_dir}/setup":
    command     => "rm -r -f '${shop_dir}/setup'",
    path        => $oxid::params::path,
    refreshonly => $refreshonly,
    onlyif      => "test -d '${shop_dir}/setup'"
  }

  exec { "${name} file permissions check ${shop_dir}/updateApp":
    command     => "rm -r -f '${shop_dir}/updateApp'",
    path        => $oxid::params::path,
    refreshonly => $refreshonly,
    onlyif      => "test -d '${shop_dir}/updateApp'"
  }

  exec { "${name} file permissions check ${shop_dir}":
    command     => "chown -R '$owner':'$group' '${shop_dir}' && chmod -R ug+rw '${shop_dir}'",
    path        => $oxid::params::path,
    onlyif      => "test -d '${shop_dir}'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file permissions check ${shop_dir}/setup", "${name} file permissions check ${shop_dir}/updateApp"]
  }

  exec { "${name} file permissions check ${shop_dir}/config.inc.php":
    command     => "chown '$owner':'$group' '${shop_dir}/config.inc.php' && chmod 0400 '${shop_dir}/config.inc.php'",
    path        => $oxid::params::path,
    onlyif      => "test -f '${shop_dir}/config.inc.php'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file permissions check ${shop_dir}"]
  }

  exec { "${name} file permissions check ${shop_dir}/.htaccess":
    command     => "chown '$owner':'$group' '${shop_dir}/.htaccess' && chmod 0400 '${shop_dir}/.htaccess'",
    path        => $oxid::params::path,
    onlyif      => "test -f '${shop_dir}/.htaccess'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file permissions check ${shop_dir}"]
  }

  exec { "${name} file exist check ${compile_dir}":
    command     => "mkdir -p '${compile_dir}'",
    path        => $oxid::params::path,
    unless      => "test -d '${compile_dir}'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file permissions check ${shop_dir}"]
  }

  exec { "${name} file clean ${compile_dir}":
    command     => "find '${compile_dir}' ! -name .htaccess -type f -delete",
    path        => $oxid::params::path,
    refreshonly => $refreshonly,
    require     => Exec["${name} file exist check ${compile_dir}"]
  }

  exec { "${name} file permissions check ${compile_dir}":
    command     => "chown -R '$owner':'$group' '${compile_dir}' && chmod -R ug+rw '${compile_dir}'",
    path        => $oxid::params::path,
    onlyif      => "test -d '${compile_dir}'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file clean ${compile_dir}"]
  }

  exec { "${name} file exist check ${shop_dir}/log":
    command     => "mkdir -p '${shop_dir}/log'",
    path        => $oxid::params::path,
    unless      => "test -d '${shop_dir}/log'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file permissions check ${shop_dir}"]
  }

  exec { "${name} file permissions check ${shop_dir}/log":
    command     => "chown -R '$owner':'$group' '${shop_dir}/log' && chmod -R ug+rw '${shop_dir}/log'",
    path        => $oxid::params::path,
    onlyif      => "test -d '${shop_dir}/log'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file exist check ${shop_dir}/log"]
  }

  exec { "${name} file exist check ${shop_dir}/out/pictures":
    command     => "mkdir -p '${shop_dir}/out/pictures'",
    path        => $oxid::params::path,
    unless      => "test -d '${shop_dir}/out/pictures'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file permissions check ${shop_dir}"]
  }

  exec { "${name} file permissions check ${shop_dir}/out/pictures":
    command     => "chown -R '$owner':'$group' '${shop_dir}/out/pictures' && chmod -R ug+rw '${shop_dir}/out/pictures'",
    path        => $oxid::params::path,
    onlyif      => "test -d '${shop_dir}/out/pictures'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file exist check ${shop_dir}/out/pictures"]
  }

  exec { "${name} file exist check ${shop_dir}/out/media":
    command     => "mkdir -p '${shop_dir}/out/media'",
    path        => $oxid::params::path,
    unless      => "test -d '${shop_dir}/out/media'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file permissions check ${shop_dir}"]
  }

  exec { "${name} file permissions check ${shop_dir}/out/media":
    command     => "chown -R '$owner':'$group' '${shop_dir}/out/media' && chmod -R ug+rw '${shop_dir}/out/media'",
    path        => $oxid::params::path,
    onlyif      => "test -d '${shop_dir}/out/media'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file exist check ${shop_dir}/out/media"]
  }

  exec { "${name} file exist check ${shop_dir}/out/downloads":
    command     => "mkdir -p '${shop_dir}/out/downloads'",
    path        => $oxid::params::path,
    unless      => "test -d '${shop_dir}/out/downloads'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file permissions check ${shop_dir}"]
  }

  exec { "${name} file permissions check ${shop_dir}/out/downloads":
    command     => "chown -R '$owner':'$group' '${shop_dir}/out/downloads' && chmod -R ug+rw '${shop_dir}/out/downloads'",
    path        => $oxid::params::path,
    onlyif      => "test -d '${shop_dir}/out/downloads'",
    refreshonly => $refreshonly,
    require     => Exec["${name} file exist check ${shop_dir}/out/downloads"]
  }
}