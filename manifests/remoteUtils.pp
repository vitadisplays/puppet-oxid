include oxid::params

# Define: oxid::rsyncGet
#
# This define use rsync to synchronize data from a remote source to a oxid shop target
#
# Parameters:
#
#   - name        relative path to copy
#   - source      source to sync from. Syntax: "root@example.com:/srv/www/oxid"
#   - shop_dir    target shop directory to copy to
#   - keyfile     ssh keyfile to use. Default is "~/.ssh/id_rsa".
#
# Actions:
#   - synchronize data
#
# Requires:
#   - Oxid shop dir
#
# Sample Usage:
#    oxid::rsyncGet { "out/pictures":
#     source      => "root@example.com:/srv/www/oxid"
#     shop_dir    => "/srv/www/oxid",
#     keyfile     => "~/.ssh/id_rsa",
#    }
define oxid::rsyncGet ($source, $shop_dir, $keyfile = "~/.ssh/id_rsa", $timeout) {
  if !defined(Class[oxid::package::utils]) {
    include oxid::package::utils
  }

  exec { "rsync -raz -e \"ssh -i ${keyfile} -o StrictHostKeyChecking=no\" ${source}/${name}/ ${shop_dir}/${name}":
    path    => $oxid::params::path,
    timeout => $timeout,
    require => Class[oxid::package::utils]
  }
}

# Define: oxid::sshFetchRemoteData
#
# This define fetch remote data of an existing oxid instance.
#
# Parameters:
#   - shop_dir      target shop dir, Required.
#   - remote_dir    source remote dir to fetch from, Required.
#   - includes      relative paths to fetch, Default is ['out/pictures', 'out/media'].
#   - keyfile       ssh key file to use. Default is "~/.ssh/id_rsa".
#   - timeout       timeout. Default is 18000.
#   - backup_dir    if defined, this define fetch data to a backup file first.
#   - compression   compression for backup file. gzip, bzip or none are supported. Default is 'gzip'.
#   - purge         if set to true, existing backup file is purged and a new remote fetch will be execute. Otherwise the backup file be used, and no remote fetch will be done.
#
# Actions:
#   - fetch data via ssh
#   - Store content to an archive
#
# Requires:
#   - Oxid instance
#
# Sample Usage:
#    oxid::sshFetchRemoteData { "root@myremotehostname":
#     shop_dir => "/srv/www/oxid",
#     remote_dir => "/srv/www/oxid"
#    }
define oxid::sshFetchRemoteData (
  $shop_dir,
  $remote_dir,
  $includes    = ['out/pictures', 'out/media'],
  $backup_dir  = undef,
  $keyfile     = "~/.ssh/id_rsa",
  $timeout     = 18000,
  $compression = 'gzip',
  $purge       = true) {
  validate_array($includes)
  validate_bool($purge)
  validate_absolute_path($shop_dir, $remote_dir)
  validate_re($name, '^.*@.*$')

  if defined(Oxid::Conf["oxid"]) {
    Oxid::Conf["oxid"] ~> Oxid::SshFetchRemoteData[$name]
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
        $create_prg = "ssh -i '${keyfile}' -o StrictHostKeyChecking=no ${name} 'cd \"${remote_dir}\" ; find ${includes_str} -type f -print0 | tar -cj -T - --null' > '${$archive}'"
        $extract_prg = "tar -xjf '${$archive}' --directory '${shop_dir}'"
      }
      'gzip'  : {
        $archive = "${backup_dir}/data.tar.gz"
        $create_prg = "ssh -i '${keyfile}' -o StrictHostKeyChecking=no ${name} 'cd \"${remote_dir}\" ; find ${includes_str} -type f -print0 | tar -cz -T - --null' > '${$archive}'"
        $extract_prg = "tar -xzf '${$archive}' --directory '${shop_dir}'"
      }
      'none'  : {
        $archive = "${backup_dir}/data.tar"
        $create_prg = "ssh -i '${keyfile}' -o StrictHostKeyChecking=no ${name} 'cd \"${remote_dir}\" ; find ${includes_str} -type f -print0 | tar -c -T - --null' > '${$archive}'"
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

    oxid::rsyncGet { $includes:
      source   => "${name}:${remote_dir}",
      keyfile  => $keyfile,
      shop_dir => $shop_dir,
      timeout  => $timeout,
      notify   => defined(Oxid::FileCheck["oxid"]) ? {
        true    =>  Oxid::FileCheck["oxid"],
        default => undef
      }
    }
  }
}

# Define: oxid::sshFetchRemoteSQL
#
# This define fetch remote sql dump of an existing oxid database instance.
#
# Parameters:
#   - db_name            local database name to import to. Default is "oxid".
#   - db_user            local database user to import to. Default is "oxid".
#   - db_password        local database password to import to. Default is "oxid".
#   - db_host            local database host to import to. Default is "localhost".
#   - db_port            local database port to import to. Default is 3306.
#   - remote_db_name     remote database name to import from. Default is "oxid".
#   - remote_db_user     remote database user to import from. Default is "oxid".
#   - remote_db_password remote database password to import from. Default is "oxid".
#   - remote_db_host     remote database host to import from. Default is "oxid".
#   - remote_db_port     remote database port to import from. Default is 3306.
#   - dump_tables        remote tables to dump.
#   - dump_options       remote dump option to use.
#   - keyfile            ssh key file to use. Default is "~/.ssh/id_rsa".
#   - timeout            timeout. Default is 18000.
#   - backup_dir         if defined, this define fetch data to a backup file first.
#   - compression        compression for backup file. gzip, bzip or none are supported. Default is 'gzip'.
#   - purge              if set to true, existing backup file is purged and a new remote fetch will be execute. Otherwise the backup file be used, and no remote fetch will be done.
#
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
#    remote_db_name => "oxid",
#    remote_db_user => "oxid",
#    remote_db_password => "secret",
#    dump_tables => "$(mysql --user='oxid' --password='secret' -B -N -e \"Select TABLE_NAME FROM information_schema.TABLES WHERE
#    TABLE_SCHEMA = '\\''oxid'\\'' AND TABLE_TYPE != '\\''VIEW'\\''\" | grep -v Tables_in | xargs)",
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
  $keyfile,
  $dump_tables        = undef,
  $dump_options       = $oxid::params::default_remote_dump_options_utf8,
  $timeout            = 18000,
  $compression        = 'gzip',
  $purge              = true) {
  validate_array($dump_options)
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
    exec { "ssh -i '${keyfile}' -o StrictHostKeyChecking=no ${name} 'mysqldump --host=\"${remote_db_host}\" --port=${remote_db_port} --user=\"${remote_db_user}\" --password=\"${remote_db_password}\" ${dump_options_str} \"${remote_db_name}\" ${dump_tables_str} ${create_prg}' > ${archive}"
    :
      path    => $oxid::params::path,
      unless  => "test -f '${archive}'",
      timeout => $timeout,
      require => Class["oxid::package::packer"]
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
    exec { "ssh -i '${keyfile}' -o StrictHostKeyChecking=no ${name} 'mysqldump --host=\"${remote_db_host}\" --port=${remote_db_port} --user=\"${remote_db_user}\" --password=\"${remote_db_password}\" ${dump_options_str} \"${remote_db_name}\" ${dump_tables_str} ${create_prg}' | mysql --host=\"${db_host}\" --port=${db_port} --user=\"${db_user}\" --password=\"${db_password}\" \"${db_name}\""
    :
      path    => $oxid::params::path,
      timeout => $timeout
    }
  }
}