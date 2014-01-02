define oxid::module (
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
  $module_path = get_module_path('oxid')

  validate_string($name)
  validate_re($ensure, ["^present$", "^installed$", "^absent$", "^deleted$"])

  if $files != undef {
    validate_array($files)

    $deletes = join(suffix(prefix($files, "'${shop_dir}"), "'"), " ")

    $delete_cmd = "rm -r -f ${deletes}"
  } else {
    $delete_cmd = "rm -r -f ${shop_dir}/modules/${name}"
  }

  case $ensure {
    /absent|deleted/    : {
      $jsonHash = {
        'command'   => "delete",
        'module'    => $class_mapping,
        'shopid'    => $shopid,
        'host'      => "${host}:${port}",
        'db'        => $db,
        'user'      => $user,
        'password'  => $password,
        'configkey' => $config_key
      }

      $cmd = inline_template('<%= require "json"; JSON.generate @jsonHash %>')

      oxid::php::runner { "oxid-module ${name} absent":
        source  => "${module_path}/functions/oxid/oxid-modules.php",
        options => ["'${cmd}'"]
      } ->
      exec { "${name}: purge module files":
        command => $delete_cmd,
        path    => $oxid::params::path
      }
    }

    /present|installed/ : {
      $jsonHash = {
        'command'   => "add",
        'module'    => $class_mapping,
        'shopid'    => $shopid,
        'host'      => "${host}:${port}",
        'db'        => $db,
        'user'      => $user,
        'password'  => $password,
        'configkey' => $config_key
      }

      $cmd = inline_template('<%= require "json"; JSON.generate @jsonHash %>')

      exec { "${name}: purge module files":
        command => $delete_cmd,
        path    => $oxid::params::path
      } ->
      oxid::unpack_module { $name:
        destination => $shop_dir,
        source      => $source,
        repository  => $repository,
        copy_map    => $copy_map
      } ->
      oxid::php::runner { "module ${name} ${ensure}":
        source  => "${module_path}/functions/oxid/oxid-modules.php",
        options => ["'${cmd}'"]
      } -> oxid::fileCheck { $name:
        shop_dir    => $shop_dir,
        compile_dir => $compile_dir,
        owner       => $owner,
        group       => $group
      }
    }
  }
}

define oxid::unpack_module ($destination, $source = undef, $repository, $timeout = 0, $copy_map) {
  $repo_config = $oxid::params::repository_configs["${repository}"]
  $repo_dir = $repo_config['directory']
  $tmp_dir = $oxid::params::tmp_dir

  $file = inline_template("<%= File.join(@repo_dir, @source) %>")
  $extract_dir = inline_template("<%= File.join(@tmp_dir, File.basename(@source, '.*')) %>")

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
    } -> exec { "${name}: rm -r -f '${extract_dir}'":
      command => "rm -r -f '${extract_dir}'",
      path    => $oxid::params::path,
      onlyif  => "test -d '${extract_dir}'"
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

define oxid::unpack_copy_helper ($root_dir, $copy_map, $extract_dir) {
  $key = inline_template("<%= @name.to_s[@extract_dir.to_s.length..-1] %>")
  $destination = inline_template("<%= File.join(@root_dir, @copy_map[@key]) %>")

  exec { "${name}: mkdir -p '${destination}'":
    command => "mkdir -p '${destination}'",
    path    => $oxid::params::path,
    onlyif  => "test -d '${name}'",
    unless  => "test -d '${destination}'"
  } ->
  exec { "cp -r -f ${name} '${destination}'/":
    path   => $oxid::params::path,
    onlyif => "test -e '${name}'"
  }
}