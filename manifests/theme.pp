define oxid::theme (
  $active        = true,
  $shop_dir      = $oxid::params::shop_dir,
  $compile_dir   = $oxid::params::compile_dir,
  $owner         = $apache::params::user,
  $group         = $apache::params::group,
  $shopid        = $oxid::params::default_shopid,
  $source        = undef,
  $repository    = undef,
  $class_mapping = undef,
  $copy_map      = undef,
  $files         = undef,
  $ensure        = "present",
  $host          = $oxid::params::db_host,
  $port          = $oxid::params::db_port,
  $db            = $oxid::params::db_name,
  $user          = $oxid::params::db_user,
  $password      = $oxid::params::db_password,
  $config_key    = $oxid::params::config_key) {
  validate_bool($active)
  validate_string($name)
  validate_re($ensure, ["^present$", "^installed$", "^absent$", "^deleted$"])

  if $files != undef {
    validate_array($files)

    $deletes = join(suffix(prefix($files, "'${shop_dir}"), "'"), " ")

    $delete_cmd = "rm -r -f ${deletes}"
  } else {
    $delete_cmd = "rm -r -f ${shop_dir}/out/${name}"
  }

  case $ensure {
    /absent|deleted/    : {
      if is_string($name) {
        exec { "rm -r -f '${shop_dir}/out/${name}'":
          path   => $oxid::params::path,
          onlyif => "test -d '${shop_dir}/out/${name}'"
        }
      }
    }

    /present|installed/ : {
      oxid::unpack_theme { $name:
        destination => $shop_dir,
        source      => $source,
        repository  => $repository,
        copy_map    => $copy_map
      } -> oxid::fileCheck { $name:
        shop_dir    => $shop_dir,
        compile_dir => $compile_dir,
        owner       => $owner,
        group       => $group
      }

      if $active == true {
        oxid::config { $name:
          shopid   => 1,
          host     => $host,
          port     => $port,
          db       => $db,
          user     => $user,
          password => $password,
          configs  => {
            "sTheme" => $name
          }
          ,
          require  => Oxid::Unpack_theme[$name]
        }
      }
    }
  }
}

define oxid::unpack_theme ($destination, $source = undef, $repository, $timeout = 0, $copy_map = undef) {
  $repo_config = $oxid::params::repository_configs["${repository}"]
  $repo_dir = $repo_config['directory']
  $tmp_dir = $oxid::params::tmp_dir

  $file = inline_template("<%= File.join(@repo_dir, @source) %>")
  $extract_dir = inline_template("<%= File.join(@tmp_dir, File.basename(@source)) %>")

  oxid::repository::get { $name:
    source     => $source,
    repository => $repository
  }

  if $copy_map != undef {
    validate_hash($copy_map)
    $copy_dirs = prefix(keys($copy_map), "${extract_dir}/")

    exec { "${name}: mkdir -p '${extract_dir}'":
      command => "mkdir -p '${extract_dir}'",
      path    => $oxid::params::path,
      unless  => "test -d '${extract_dir}'"
    } ->
    ::oxid::unpack { $name:
      source      => $file,
      destination => $extract_dir,
      timeout     => $timeout,
      require     => Oxid::Repository::Get[$name]
    } ->
    ::oxid::unpack_copy_helper { $copy_dirs:
      copy_map    => $copy_map,
      root_dir    => $destination,
      extract_dir => "${extract_dir}/"
    }
  } elsif $copy_map == undef {
    ::oxid::unpack { $name:
      source      => $file,
      destination => $destination,
      timeout     => $timeout,
      require     => Oxid::Repository::Get[$name]
    }
  } else {
    fail("Value for copy_map undef or hash expected.")
  }
}