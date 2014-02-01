# Define: oxid::module
#
# This define install and activate an oxid module.
#
# This used a php script, using bootstrap.php, in the shop directory to activate the module.
#
# Parameters:
#
#   - ensure              activated, installed, overwrite, deactivated or purged. 'installed' install the module, but do not
#   activate the module, 'activated' does. 'overwrite' is like activated, but overrides class_mapping values. 'deactivated'
#   deactivate the module, but do nor remove module files, purged does. Default is activated.
#   - repository          The repository to get from.
#   - source              The location of the setup archive in the defined repository.
#   - shopid              Shop id, Used for Enterprise Editions. Default is oxbase.
#   - shop_dir            The oxid shop directroy.
#   - compile_dir         The oxid compile directroy
#   - configurations      Hash configurations options. See define oxid::oxconfig for more details.
#   - class_mapping       Hash for extending oxid classes. Used only for legacy mode. Oxid Version before 4.5.x.
#                         Single Mapping:
#                         class_mapping => {
#                           "classToExtend" => "path1/class1"
#                         }
#
#                         Mutiple mapping:
#                         class_mapping => {
#                           "classToExtend" => ["path1/class1", "path2/class2"]
#                         }
#                         The define will recordnize the uniqueness of the arrays. Existing class to extend, will be appended with
#                         new entries.
#                         if ensure => overwrite the Existing class to extend will be be overwriten with the define entries. This
#                         will remove old mapping entries for then given class to extend.
#   - user                The owner of the directories
#   - group               The group of the directories
#   - copy_filter            Hash to help unpacking and coping files. Default is undef, that unpack as flat file. Use {'copy_this/'
#   => '', 'changed_full/' => '' } for oxid default structure. Works only for a directory defintion. Have to improved in the next versions.
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
#
# Sample Legacy Usage:
#    oxid::module {'oepaypal':
#      shopid  => 1,
#      shop_dir => "/srv/www/oxid",
#      configurations =>  {
#       'confbools'     => {
#         'bl_xxxx' => false
#       }
#     },
#
#   }
define oxid::module (
  $shop_dir       = $oxid::params::shop_dir,
  $compile_dir    = $oxid::params::compile_dir,
  $user           = $apache::params::user,
  $group          = $apache::params::group,
  $shopid         = $oxid::params::default_shopid,
  $source         = undef,
  $repository     = undef,
  $copy_filter     = undef,
  $files          = undef,
  $ensure         = "activated",
  $configurations = undef,
  $class_mapping  = undef) {
  validate_string($name)
  validate_re($ensure, ["^activated$", "^installed$", "^overwrite", "^deactivated$", "^purged$"])

  $_req = defined(Class[oxid]) ? {
    true    => Class[oxid],
    default => undef
  }

  $php_file = inline_template("<%= File.join(@shop_dir, (0...32).map{ ('a'..'z').to_a[rand(26)] }.join + '_module.php') %>")
  $json_class_mapping = $class_mapping ? {
    undef   => '',
    default => inline_template('<%= require "json"; JSON.generate @class_mapping %>')
  }

  if $files != undef {
    validate_array($files)

    $deletes = join(suffix(prefix($files, "'${shop_dir}"), "'"), " ")

    $delete_cmd = "rm -r -f ${deletes}"
  } else {
    $delete_cmd = "rm -r -f ${shop_dir}/modules/${name}"
  }

  case $ensure {
    /deactivated|purged/            : {
      $command = "deactivate"

      file { $php_file:
        ensure  => 'present',
        owner   => $user,
        group   => $group,
        mode    => "0755",
        content => template("oxid/oxid/php/module.erb"),
        require => $_req
      } ->
      oxid::php::runner { $php_file: source => $php_file, } ->
      exec { "rm -f '${php_file}'": path => $oxid::params::path }

      if $ensure == 'purged' {
        exec { "${name}: ${ensure} module files":
          command => $delete_cmd,
          path    => $oxid::params::path,
          require => Oxid::Php::Runner[$php_file]
        }
      }
    }

    /activated|installed|overwrite/ : {
      $command = "activate"

      exec { "${name}: purge module files":
        command => $delete_cmd,
        path    => $oxid::params::path,
        require => $_req
      } ->
      oxid::unpack_module { $name:
        destination => $shop_dir,
        source      => $source,
        repository  => $repository,
        copy_filter    => $copy_filter
      } -> oxid::fileCheck { $name:
        shop_dir    => $shop_dir,
        compile_dir => $compile_dir,
        owner       => $user,
        group       => $group
      } ->
      file { $php_file:
        ensure  => 'present',
        content => template("oxid/oxid/php/module.erb"),
        mode    => "0755",
        owner   => $user,
        group   => $group
      } ->
      oxid::php::runner { $php_file:
        source => $php_file,
        user   => $user,
        group  => $group
      } ->
      exec { "rm -f '${php_file}'": path => $oxid::params::path }

      if $configurations != undef {
        oxid::oxconfig { $name:
          shop_dir       => $shop_dir,
          shopid         => $shopid,
          module         => $name,
          configurations => $configurations,
          type           => $class_mapping ? {
            undef   => 'module',
            default => "default"
          },
          require        => Oxid::Php::Runner[$php_file]
        }
      }
    }
  }
}

define oxid::unpack_module ($destination, $source = undef, $repository, $timeout = 0, $copy_filter = undef) {
  $repo_config = $oxid::params::repository_configs["${repository}"]
  $repo_dir = $repo_config['directory']
  $tmp_dir = $oxid::params::tmp_dir

  $file = inline_template("<%= File.join(@repo_dir, @source) %>")
  $extract_dir = inline_template("<%= File.join(@tmp_dir, File.basename(@source, '.*')) %>")

  oxid::repository::get { $name:
    source     => $source,
    repository => $repository
  }

  if $copy_filter != undef {
    validate_hash($copy_filter)
    $copy_dirs = prefix(keys($copy_filter), "${extract_dir}/")

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
      copy_filter    => $copy_filter,
      root_dir    => $destination,
      extract_dir => "${extract_dir}/"
    } -> exec { "${name}: rm -r -f '${extract_dir}'":
      command => "rm -r -f '${extract_dir}'",
      path    => $oxid::params::path,
      onlyif  => "test -d '${extract_dir}'"
    }
  } elsif $copy_filter == undef {
    ::oxid::unpack { $name:
      source      => $file,
      destination => $destination,
      timeout     => $timeout,
      require     => Oxid::Repository::Get[$name]
    }
  } else {
    fail("Value for copy_filter undef or hash expected.")
  }
}

define oxid::unpack_copy_helper ($root_dir, $copy_filter, $extract_dir) {
  $key = inline_template("<%= @name.to_s[@extract_dir.to_s.length..-1] %>")
  $destination = inline_template("<%= File.join(@root_dir, @copy_filter[@key]) %>")

  exec { "${name}: mkdir -p '${destination}'":
    command => "mkdir -p '${destination}'",
    path    => $oxid::params::path,
    onlyif  => "test -d '${name}'",
    unless  => "test -d '${destination}'"
  } ->
  exec { "cp -r -f ${name}/* '${destination}'/":
    path   => $oxid::params::path,
    onlyif => "test -e '${name}'"
  }
}