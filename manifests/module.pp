# Define: oxid::module
#
# This define install and activate an oxid module.
#
# This used a php script, using bootstrap.php, in the shop directory to activate the module.
#
# Parameters:
#
#   - ensure              present or absen. Default is present.
#   - repository          The repository to get from
#   - source              The location of the setup archive in the defined repository. For output mapping use a hash, like {
#   "index.php" => "OXID_ESHOP_CE_CURRENT.zip"}. This will download index.php to download file OXID_ESHOP_CE_CURRENT.zip. Helpfully
#   to download from oxid default location.
#   - shopid              Shop id, Used for Enterprise Editions. Default is oxbase.
#   - active              If true, activate module. Default is true.
#   - shop_dir            The oxid shop directroy.
#   - compile_dir         The oxid compile directroy
#   - configurations      Hash configurations options. See define oxid::oxconfig for more details.
#   - user                The owner of the directories
#   - group               The group of the directories
#   - copy_map            Hash to help unpacking and coping files. Default is undef, that unpack as flat file. Use {'copy_this/'
#   => '', 'changed_full/' => '' } for oxid default structure.
#   - files               Array of files/directories to delete. Only used if ensure => 'absent'.
#
# Actions:
#   - Download and install module
#   - activate module
#   - Configure module
#   - Check File permission, owner and group
#
# Requires:
#   - Repository
#   - Apache instance
#   - MySQL Server instance
#   - PHP
#   - Configured oxid shop
#
# Sample Usage:
#    oxid::module {'oepaypal':
#      shopid  => 1,
#      shop_dir => "/srv/www/oxid",
#      configurations =>  {
#       'confbools'     => {
#         'bl_xxxx' => false
#       }
#     }
#   }
define oxid::module (
  $active         = true,
  $shop_dir       = $oxid::params::shop_dir,
  $compile_dir    = $oxid::params::compile_dir,
  $user           = $apache::params::user,
  $group          = $apache::params::group,
  $shopid         = $oxid::params::default_shopid,
  $source         = undef,
  $repository     = undef,
  $copy_map       = undef,
  $files          = undef,
  $ensure         = "present",
  $configurations = undef) {
  validate_string($name)
  validate_re($ensure, ["^present$", "^installed$", "^absent$", "^deleted$"])

  if $files != undef {
    validate_array($files)

    $deletes = join(suffix(prefix($files, "'${shop_dir}"), "'"), " ")

    $delete_cmd = "rm -r -f ${deletes}"
  } else {
    $delete_cmd = "rm -r -f ${shop_dir}/modules/${name}"
  }

  $php_file = inline_template("<%= File.join(@shop_dir, (0...32).map{ ('a'..'z').to_a[rand(26)] }.join + '_module.php') %>")

  case $ensure {
    /absent|deleted/    : {
      $command = "deactivate"

      file { $php_file:
        ensure  => 'present',
        owner   => $user,
        group   => $group,
        mode    => "0755",
        content => template("oxid/oxid/php/module.erb")
      } ->
      oxid::php::runner { $php_file: source => $php_file, } ->
      exec { "rm -f '${php_file}'": path => $oxid::params::path } ->
      exec { "${name}: ${ensure} module files":
        command => $delete_cmd,
        path    => $oxid::params::path
      }
    }

    /present|installed/ : {
      $command = "activate"

      exec { "${name}: purge module files":
        command => $delete_cmd,
        path    => $oxid::params::path
      } ->
      oxid::unpack_module { $name:
        destination => $shop_dir,
        source      => $source,
        repository  => $repository,
        copy_map    => $copy_map
      } -> oxid::fileCheck { $name:
        shop_dir    => $shop_dir,
        compile_dir => $compile_dir,
        owner       => $user,
        group       => $group
      }

      if $active == true {
        file { $php_file:
          ensure  => 'present',
          content => template("oxid/oxid/php/module.erb"),
          mode    => "0755",
          owner   => $user,
          group   => $group
        } ->
        oxid::php::runner { $php_file:
          source  => $php_file,
          user    => $user,
          group   => $group,
          require => Oxid::FileCheck[$name]
        } ->
        exec { "rm -f '${php_file}'": path => $oxid::params::path }
      }

      if $configurations != undef {
        oxid::oxconfig { $name:
          shop_dir       => $shop_dir,
          shopid         => $shopid,
          module         => $name,
          configurations => $configurations,
          type           => 'module',
          require        => $active ? {
            true    => Oxid::Php::Runner[$php_file],
            default => Oxid::FileCheck[$name]
          }
        }
      }
    }
  }
}

define oxid::unpack_module ($destination, $source = undef, $repository, $timeout = 0, $copy_map = undef) {
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