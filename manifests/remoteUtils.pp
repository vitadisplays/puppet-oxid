include oxid::params

# Define: oxid::sshFetchRemoteData
#
# This define fetch remote data of an existing oxid instance.
#
# Parameters:
#
# Actions:
#   - fetch data via ssh
#   - Store content to an archive
#
# Requires:
#   - Repository
#   - Oxid instance
#
# Sample Usage:
#    oxid::sshFetchRemoteData { "root@myremotehostname":
#     shop_dir => "/srv/www/oxid",
#     remote_dir => "/srv/www/oxid",
#     ssh_ident_content => file("path to private key"),
#    }
define oxid::sshFetchRemoteData (
  $shop_dir,
  $remote_dir,
  $includes    = ["out/pictures", "out/media"],
  $backup_dir  = undef,
  $ssh_options = ['-C', '-o StrictHostKeyChecking=no'],
  $ssh_ident_content,
  $timeout     = 18000,
  $compression = 'gzip',
  $purge       = true) {
  validate_array($ssh_options, $includes)
  validate_bool($purge)
  validate_absolute_path($shop_dir, $remote_dir)
  validate_re($name, '^.*@.*$')

  if defined(Oxid::Conf["oxid"]) {
    Oxid::Conf["oxid"] ~> Oxid::SshFetchRemoteData[$name]
  }

  $tmp_dir = $oxid::params::tmp_dir
  $ident_file = inline_template("<%= File.join(@tmp_dir, (0...32).map{ ('a'..'z').to_a[rand(26)] }.join + '.private') %>")

  $option_str = $ssh_options ? {
    undef   => '',
    default => join(unique(concat($ssh_options, ["-i '${ident_file}'"])), ' ')
  }

  exec { "${name}: data mkdir -p '${tmp_dir}'":
    command => "mkdir -p '${tmp_dir}'",
    path    => $oxid::params::path,
    unless  => "test -d '${tmp_dir}'"
  } ->
  file { $ident_file:
    ensure  => present,
    content => $ssh_ident_content,
    mode    => 0600
  }

  exec { "rm -f '${ident_file}'":
    path        => $oxid::params::path,
    onlyif      => "test -f '${ident_file}'",
    refreshonly => true
  }

  if $backup_dir != undef {
    if !defined(Class[oxid::package::packer]) {
      include oxid::package::packer
    }

    $includes_str = join($includes, ' ')
    $backup_file = inline_template('<%= File.join(@backup_dir, @name.split("@").last) %>')

    case $compression {
      'bzip2' : {
        $archive = "${backup_dir}/data.tar.bz2"
        $create_prg = "ssh ${$option_str} ${name} 'cd \"${remote_dir}\" ; find ${includes_str} -type f -print0 | tar -cj -T - --null' > '${$archive}'"
        $extract_prg = "tar -xjf '${$archive}' --directory '${shop_dir}'"
      }
      'gzip'  : {
        $archive = "${backup_dir}/data.tar.gz"
        $create_prg = "ssh ${$option_str} ${name} 'cd \"${remote_dir}\" ; find ${includes_str} -type f -print0 | tar -cz -T - --null' > '${$archive}'"
        $extract_prg = "tar -xzf '${$archive}' --directory '${shop_dir}'"
      }
      'none'  : {
        $archive = "${backup_dir}/data.tar"
        $create_prg = "ssh ${$option_str} ${name} 'cd \"${remote_dir}\" ; find ${includes_str} -type f -print0 | tar -c -T - --null' > '${$archive}'"
        $extract_prg = "tar -xf '${$archive}' --directory '${shop_dir}'"
      }

      default : {
        fail("${compression} not supported.")
      }
    }

    if $purge {
      exec { "${name} purge ${archive}'":
        command => "rm -f -r '${archive}'",
        path    => $oxid::params::path,
        unless  => "test -e '${archive}'",
        before  => Exec["${name}: data mkdir -p '${backup_dir}'"]
      }
    }
    exec { "${name}: data mkdir -p '${backup_dir}'":
      command => "mkdir -p '${backup_dir}'",
      path    => $oxid::params::path,
      unless  => "test -d '${backup_dir}'"
    } ->
    exec { $create_prg:
      path    => $oxid::params::path,
      unless  => "test -f '${archive}'",
      timeout => $timeout,
      notify  => Exec["rm -f '${ident_file}'"],
      require => Class[oxid::package::packer]
    } ->
    exec { $extract_prg:
      path    => $oxid::params::path,
      timeout => $timeout,
      notify  => defined(Oxid::FileCheck["oxid"]) ? {
        true    => Oxid::FileCheck["oxid"],
        default => undef
      },
      require => Class[oxid::package::packer]
    }
  } else {
    if (count($includes) < 1) {
      fail("No includes defined.")
    }

    if !defined(Class[oxid::package::utils]) {
      include oxid::package::utils
    }

    $includes_str = join(prefix(suffix($includes, "'"), "--include '"), ' ')

    $commands = split(inline_template("<%= @includes.collect{|i| 'rsync -ravz -e \"ssh ' + @option_str + '\" \"' + @name + '\":\"' + File.join(@remote_dir, i) + '/\" \"' + File.join(@shop_dir, i) + '\" ; ' } %>"
    ), ' ; ')

    exec { $commands:
      path    => $oxid::params::path,
      timeout => $timeout,
      notify  => defined(Oxid::FileCheck["oxid"]) ? {
        true    => [Exec["rm -f '${ident_file}'"], Oxid::FileCheck["oxid"]],
        default => Exec["rm -f '${ident_file}'"]
      },
      require => [Class[oxid::package::utils], File[$ident_file]]
    }
  }
}

# Define: oxid::sshFetchRemoteSQL
#
# This define fetch remote sql dump of an existing oxid database instance.
#
# Parameters:
#
# Actions:
#   - fetch sql dump via ssh
#   - Store content to an backup directory
#
# Requires:
#   - Repository
#   - Oxid instance
#
# Sample Usage:
#  oxid::sshFetchRemoteSQL {"root@myremotehostname":
#    db_name => "oxid",
#    db_user => "oxid",
#    db_password => "secret",
#    ssh_ident_content => file("path to private key"),
#    remote_db_name => "oxid",
#    remote_db_user => "oxid",
#    remote_db_password => "secret",
#  }
#
# Dump all tables. using default dump_options (utf8). See class oxid::params for more details.
#
#  oxid::sshFetchRemoteSQL {"root@myremotehostname":
#    db_name => "oxid",
#    db_user => "oxid",
#    db_password => "secret",
#    ssh_ident_content => file("path to private key"),
#    remote_db_name => "oxid",
#    remote_db_user => "oxid",
#    remote_db_password => "secret",
#    dump_tables => $(mysql --user='oxid' --password='secret' -B -N -e \"Select TABLE_NAME FROM information_schema.TABLES WHERE
#    TABLE_SCHEMA = '\''oxid'\'' AND TABLE_TYPE != '\''VIEW'\''\" | grep -v Tables_in | xargs),
#    dump_options => $oxid::params::default_remote_dump_options_latin1,
#  }
#
# Dump all tables using latin1 charset and exluding all Views. Nice sample for oxid Enterprise Edition use, to avoid mysql view
# table import.
#
define oxid::sshFetchRemoteSQL (
  $db_name            = $oxid::params::db_name,
  $db_user            = $oxid::params::db_user,
  $db_password        = $oxid::params::db_password,
  $db_host            = $oxid::params::db_host,
  $db_port            = $oxid::params::db_port,
  $remote_db_name     = $oxid::params::db_name,
  $remote_db_user     = $oxid::params::db_user,
  $remote_db_password = $oxid::params::db_password,
  $remote_db_host     = $oxid::params::db_host,
  $remote_db_port     = $oxid::params::db_port,
  $backup_dir         = undef,
  $ssh_options        = [
    '-C',
    '-o StrictHostKeyChecking=no'],
  $ssh_ident_content,
  $dump_tables        = undef,
  $dump_options       = $oxid::params::default_remote_dump_options_utf8,
  $timeout            = 18000,
  $compression        = 'gzip',
  $purge              = true) {
  validate_array($ssh_options, $dump_options)
  validate_bool($purge)
  validate_re($name, '^.*@.*$')

  if defined(Oxid::Conf["oxid"]) {
    Oxid::Conf["oxid"] ~> Oxid::SshFetchRemoteSQL[$name]
  }

  if $dump_options == undef {
    $dump_options_str = ''
  } elsif is_array($dump_options) == true {
    $dump_options_str = join(unique($dump_options), ' ')
  } else {
    validate_string($dump_options)

    $dump_options_str = $dump_options
  }

  if $dump_tables == undef {
    $dump_tables_str = ''
  } elsif is_array($dump_tables) == true {
    $dump_tables_str = shellquote(unique($dump_tables))
  } else {
    validate_string($dump_tables)

    $dump_tables_str = $dump_tables
  }

  $tmp_dir = $oxid::params::tmp_dir
  $ident_file = inline_template("<%= File.join(@tmp_dir, (0...32).map{ ('a'..'z').to_a[rand(26)] }.join + '.private') %>")

  $option_str = $ssh_options ? {
    undef   => '',
    default => join(unique(concat($ssh_options, ["-i '${ident_file}'"])), ' ')
  }

  exec { "${name}: sql mkdir -p '${tmp_dir}'":
    command => "mkdir -p '${tmp_dir}'",
    path    => $oxid::params::path,
    unless  => "test -d '${tmp_dir}'"
  } ->
  file { $ident_file:
    ensure  => present,
    content => $ssh_ident_content,
    mode    => 0600
  }

  exec { "rm -f '${ident_file}'":
    path        => $oxid::params::path,
    onlyif      => "test -f '${ident_file}'",
    refreshonly => true
  }

  if $backup_dir != undef {
    if !defined(Class[oxid::package::packer]) {
      include oxid::package::packer
    }

    $backup_file = inline_template('<%= File.join(@backup_dir, @name.split("@").last) %>')

    case $compression {
      'bzip2' : {
        $archive = "${backup_file}.sql.bz2"
        $create_prg = '| bzip2 --best'
        $extract_prg = "bunzip2"
      }
      'gzip'  : {
        $archive = "${backup_file}.sql.gz"
        $create_prg = '| gzip --best'
        $extract_prg = "gunzip"
      }
      'none'  : {
        $archive = "${backup_file}.sql"
        $create_prg = ''
        $extract_prg = undef
      }
      default : {
        fail("${compression} not supported.")
      }
    }

    exec { "${name}: sql mkdir -p '${backup_dir}'":
      command => "mkdir -p '${backup_dir}'",
      path    => $oxid::params::path,
      unless  => "test -d '${backup_dir}'"
    } ->
    exec { "ssh ${$option_str} ${name} 'mysqldump --host=\"${remote_db_host}\" --port=${remote_db_port} --user=\"${remote_db_user}\" --password=\"${remote_db_password}\" ${dump_options_str} \"${remote_db_name}\" ${dump_tables_str} ${create_prg}' > ${archive}"
    :
      path    => $oxid::params::path,
      unless  => "test -f '${archive}'",
      timeout => $timeout,
      notify  => Exec["rm -f '${ident_file}'"],
      require => [Class["oxid::package::packer"], File[$ident_file]]
    } ->
    oxid::mysql::execFile { $name:
      host        => $db_host,
      port        => $db_port,
      user        => $db_user,
      db          => $db_name,
      password    => $db_password,
      source      => $archive,
      extract_cmd => $extract_prg,
      timeout     => $timeout,
      notify      => defined(Oxid::UpdateViews["oxid"]) ? {
        true    => Oxid::UpdateViews["oxid"],
        default => undef
      }
    }

    if $purge {
      exec { "${name}: purge ${archive}":
        command => "rm -f -r '${archive}'",
        path    => $oxid::params::path,
        unless  => "test -e '${archive}'",
        before  => Exec["${name}: sql mkdir -p '${backup_dir}'"]
      }
    }
  } else {
    exec { "ssh ${$option_str} ${name} 'mysqldump --host=\"${remote_db_host}\" --port=${remote_db_port} --user=\"${remote_db_user}\" --password=\"${remote_db_password}\" ${dump_options_str} \"${remote_db_name}\" ${dump_tables_str} ${create_prg}' | mysql --host=\"${db_host}\" --port=${db_port} --user=\"${db_user}\" --password=\"${db_password}\" \"${db_name}\""
    :
      path    => $oxid::params::path,
      timeout => $timeout,
      notify  => Exec["rm -f '${ident_file}'"],
      require => File[$ident_file]
    }
  }
}