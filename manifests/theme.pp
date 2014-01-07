# Define: oxid::theme
#
# This define install and activate an oxid theme.
#
# This used a php script, using bootstrap.php, in the shop directory to activate the theme.
#
# Parameters:
#
#   - ensure              present or absen. Default is present.
#   - repository          The repository to get from
#   - source              The location of the setup archive in the defined repository. For output mapping use a hash, like {
#   "index.php" => "OXID_ESHOP_CE_CURRENT.zip"}. This will download index.php to download file OXID_ESHOP_CE_CURRENT.zip. Helpfully
#   to download from oxid default location.
#   - shopid              Shop id, Used for Enterprise Editions. Default is oxbase.
#   - active              If true, activate theme. Default is true.
#   - shop_dir            The oxid shop directroy.
#   - compile_dir         The oxid compile directroy
#   - configurations      Hash configurations options. See define oxid::oxconfig for more details.
#   - user                The owner of the directories
#   - group               The group of the directories
#   - copy_map            Hash to help unpacking and coping files. Default is undef, that unpack as flat file. Use {'copy_this/'    => '', 'changed_full/' => '' } for oxid default structure.
#   - files               Array of files/directories to delete. Only used if ensure => 'absent'.
#   - default_theme       Default theme name, to activate, if ensure => 'absent'.
# 
# Actions:
#   - Download and install theme
#   - activate theme
#   - Configure theme
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
#   oxid::theme {'azure':
#      shopid  => 1,
#      shop_dir => "/srv/www/oxid",
#      compile_dir => "/srv/www/oxid/tmp",
#      configurations =>  {
#       'confbools'     => {
#        'bl_showOpenId' => false
#       }
#    }
#  }
define oxid::theme (
  $shop_dir       = $oxid::params::shop_dir,
  $compile_dir    = $oxid::params::compile_dir,
  $user           = $apache::params::user,
  $group          = $apache::params::group,
  $shopid         = $oxid::params::default_shopid,
  $source         = undef,
  $repository     = undef,
  $copy_map       = undef,
  $files          = undef,
  $ensure         = "activated",
  $default_theme  = "azure",
  $configurations = undef) {
  validate_string($name)
  validate_re($ensure, ["^activated$", "^installed$","^deactivated$", "^purged$"])
  
  if $files != undef {
    validate_array($files)

    $deletes = join(suffix(prefix($files, "'${shop_dir}"), "'"), " ")

    $delete_cmd = "rm -r -f ${deletes}"
  } else {
    $delete_cmd = "rm -r -f ${shop_dir}/out/${name}"
  }

  $php_file = inline_template("<%= File.join(@shop_dir, (0...32).map{ ('a'..'z').to_a[rand(26)] }.join + '_theme.php') %>")

  case $ensure {
    /purged/    : {
      validate_string($name)

      exec { "rm -r -f '${shop_dir}/out/${name}'":
        path   => $oxid::params::path,
        onlyif => "test -d '${shop_dir}/out/${name}'"
      }
    }

    /activated|installed/ : {
      if $source != undef {
        oxid::unpack_theme { $name:
          destination => $shop_dir,
          source      => $source,
          repository  => $repository,
          copy_map    => $copy_map
        }

        oxid::fileCheck { $name:
          shop_dir    => $shop_dir,
          compile_dir => $compile_dir,
          owner       => $user,
          group       => $group
        }

        Oxid::Unpack_theme[$name] -> Oxid::FileCheck[$name] -> File[$php_file]
      }
    }
  }

  if $ensure == 'activated' {
    $theme = $name
  } else {
    $theme = $default_theme
  }

  file { $php_file:
    ensure  => 'present',
    content => template("oxid/oxid/php/theme.erb"),
    mode    => "0755",
    owner   => $user,
    group   => $group
  } ->
  oxid::php::runner { $php_file: source => $php_file } ->
  exec { "rm -f '${php_file}'": path => $oxid::params::path } ->
  # ## For pre oxid 4.5.x
  replace { "${name}: configure ${shop_dir}/config.inc.php":
    file        => "${shop_dir}/config.inc.php",
    pattern     => "\$this->sTheme[ ]*=[ ]*.*;",
    replacement => "\$this->sTheme = '${theme}';"
  }

  if $configurations != undef {
    oxid::oxconfig { $name:
      shop_dir       => $shop_dir,
      shopid         => $shopid,
      module         => $name,
      configurations => $configurations,
      type           => 'theme',
      require        => [Oxid::Php::Runner[$php_file], Replace["${name}: configure ${shop_dir}/config.inc.php"]]
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
    fail("Parameter copy_map expectd undef or hash value.")
  }
}