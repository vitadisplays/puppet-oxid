define oxid::php::runner (
  $source      = undef,
  $command     = undef,
  $options     = undef,
  $inifile     = $oxid::php::params::inifile,
  $timeout     = 0,
  $output      = undef,
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
    exec { "${name}: run ${source}":
      command     => "php --php-ini '${inifile}' --file '${source}' ${myoptions} ${myoutput}",
      path        => $oxid::params::path,
      timeout     => $timeout,
      refreshonly => $refreshonly
    }
  }

  if $command != undef {
    exec { "${name}: run ${command}":
      command     => "php --php-ini '${inifile}' --run '${command}' ${myoptions} ${myoutput}",
      path        => $oxid::params::path,
      timeout     => $timeout,
      refreshonly => $refreshonly
    }
  }
}