define oxid::php::runner (
  $source      = undef,
  $command     = undef,
  $options     = undef,
  $inifile     = $oxid::php::params::inifile,
  $user        = undef,
  $group       = undef,
  $timeout     = 0,
  $output      = undef,
  $returns     = 0,
  $refreshonly = false) {
  if defined(Class['php::apache']) {
    Class['php::apache'] -> Oxid::Php::Runner <| |>
  }

  if defined(Class['apache::mod::php']) {
    Class['apache::mod::php'] -> Oxid::Php::Runner <| |>
  }

  if defined(Class['php::cli']) {
    Class['php::cli'] -> Oxid::Php::Runner <| |>
  }

  if $source == undef and $command == undef {
    fail("One of the following parameter should not be null: source or command")
  }

  if $source != undef and $command != undef {
    fail("Only one of the following parameter should not be null: source or command")
  }

  $myoutput = $output ? {
    undef   => "",
    default => " > '${output}'"
  }

  if $options != undef {
    validate_array($options)

    $myoptions = join($options, ' ')
  } else {
    $myoptions = ""
  }

  if $source != undef {
    exec { "${name}: php --php-ini '${inifile}' --file '${source}' ${myoptions} ${myoutput}":
      command     => "php --php-ini '${inifile}' --file '${source}' ${myoptions} ${myoutput}",
      path        => $oxid::params::path,
      user        => $user,
      group       => $group,
      timeout     => $timeout,
      returns     => $returns,
      refreshonly => $refreshonly
    }
  }

  if $command != undef {
    exec { "${name}: php --php-ini '${inifile}' --run '${command}' ${myoptions} ${myoutput}":
      command     => "php --php-ini '${inifile}' --run '${command}' ${myoptions} ${myoutput}",
      path        => $oxid::params::path,
      user        => $user,
      group       => $group,
      timeout     => $timeout,
      returns     => $returns,
      refreshonly => $refreshonly
    }
  }
}