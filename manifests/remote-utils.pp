include oxid::params

define oxid::sshFetchRemoteData (
  $shop_dir,
  $remote_dir,
  $includes    = ["out/pictures", "out/media", "out/downloads"],
  $proxy_dir   = undef,
  $ssh_options = [
    '-C',
    '-o StrictHostKeyChecking=no'],
  $ssh_ident_content,
  $timeout     = 18000,
  $compression = 'gzip',
  $purge       = true) {
  validate_array($ssh_options, $includes)
  validate_bool($purge)
  validate_absolute_path($shop_dir, $remote_dir)
  validate_re($name, '^.*@.*$')

  if !defined(Class[oxid::package::packer]) {
    include oxid::package::packer
  }

  if defined(Oxid::Conf["oxid"]) {
    Oxid::Conf["oxid"] ~> Oxid::SshFetchRemoteData[$name]
  }

  $ident_file = inline_template("<%= (0...32).map{ ('a'..'z').to_a[rand(26)] }.join %>")
  $tmp_dir = $oxid::params::tmp_dir

  $real_import_dir = $proxy_dir ? {
    undef   => inline_template('<%= File.join(@tmp_dir, "proxy", @name.split("@").last) %>'),
    default => $proxy_dir
  }
  $option_str = $ssh_options ? {
    undef   => '',
    default => join(unique(concat($ssh_options, ["-i '${real_import_dir}/${ident_file}.private'"])), ' ')
  }

  $includes_str = join($includes, ' ')

  case $compression {
    'bzip2' : {
      $archive = "${real_import_dir}/data.tar.bz2"
      $create_prg = "ssh ${$option_str} ${name} 'cd \"${remote_dir}\" ; find ${includes_str} -type f -print0 | tar -cj -T - --null' > '${$archive}'"
      $extract_prg = "tar -xjf '${$archive}' --directory '${shop_dir}'"
    }
    'gzip'  : {
      $archive = "${real_import_dir}/data.tar.gz"
      $create_prg = "ssh ${$option_str} ${name} 'cd \"${remote_dir}\" ; find ${includes_str} -type f -print0 | tar -cz -T - --null' > '${$archive}'"
      $extract_prg = "tar -xzf '${$archive}' --directory '${shop_dir}'"
    }
    'none'  : {
      $archive = "${real_import_dir}/data.tar"
      $create_prg = "ssh ${$option_str} ${name} 'cd \"${remote_dir}\" ; find ${includes_str} -type f -print0 | tar -c -T - --null' > '${$archive}'"
      $extract_prg = "tar -xf '${$archive}' --directory '${shop_dir}'"
    }

    default : {
      fail("${compression} not supported.")
    }
  }

  $req = unique([Class[oxid::package::packer] /*,
                                               * defined(Oxid::Conf["oxid"]) ? {
                                               * true    => Oxid::Conf["oxid"],
                                               * default => Class[oxid::package::packer]
                                               *}
                                               */])

  if $purge {
    exec { "${name} purge ${archive}'":
      command => "rm -f -r '${archive}'",
      path    => $oxid::params::path,
      unless  => "test -e '${archive}'",
      before  => Exec["${name} sshRemoteData mkdir -p '${real_import_dir}'"]
    }
  }

  exec { "${name} data mkdir -p '${real_import_dir}'":
    command => "mkdir -p '${real_import_dir}'",
    path    => $oxid::params::path,
    unless  => "test -d '${real_import_dir}'"
  } ->
  file { "${real_import_dir}/${ident_file}.private":
    ensure  => present,
    content => $ssh_ident_content,
    mode    => 0600
  } ->
  exec { $create_prg:
    path    => $oxid::params::path,
    unless  => "test -f '${archive}'",
    timeout => $timeout,
    require => $req
  } ->
  exec { "rm -f '${real_import_dir}/${ident_file}.private'":
    path   => $oxid::params::path,
    onlyif => "test -f '${real_import_dir}/${ident_file}.private'"
  } ->
  exec { $extract_prg:
    path    => $oxid::params::path,
    timeout => $timeout,
    notify  => defined(Oxid::FileCheck["oxid"]) ? {
      true    => Oxid::FileCheck["oxid"],
      default => undef
    },
    require => $req
  }
}

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
  $proxy_dir          = undef,
  $ssh_options        = [
    '-C',
    '-o StrictHostKeyChecking=no'],
  $ssh_ident_content,
  $dump_tables        = [],
  $dump_options       = $oxid::params::default_remote_dump_options_utf8,
  $timeout            = 18000,
  $compression        = 'gzip',
  $purge              = true) {
  validate_array($ssh_options, $dump_options, $dump_tables)
  validate_bool($purge)
  validate_re($name, '^.*@.*$')

  if !defined(Class[oxid::package::packer]) {
    include oxid::package::packer
  }

  if defined(Oxid::Conf["oxid"]) {
    Oxid::Conf["oxid"] ~> Oxid::SshFetchRemoteSQL[$name]
  }

  $ident_file = inline_template("<%= (0...32).map{ ('a'..'z').to_a[rand(26)] }.join %>")
  $tmp_dir = $oxid::params::tmp_dir

  $real_import_dir = $proxy_dir ? {
    undef   => inline_template('<%= File.join(@tmp_dir, "proxy", @name.split("@").last) %>'),
    default => $proxy_dir
  }
  $option_str = $ssh_options ? {
    undef   => '',
    default => join(unique(concat($ssh_options, ["-i '${real_import_dir}/${ident_file}.private'"])), ' ')
  }

  $dump_options_str = join(unique($dump_options), ' ')
  $dump_tables_str = join(unique($dump_tables), ' ')

  case $compression {
    'bzip2' : {
      $archive = "${real_import_dir}/sql.bz2"
      $create_prg = '| bzip2 --best'
      $extract_prg = "bunzip2"
    }
    'gzip'  : {
      $archive = "${real_import_dir}/sql.gz"
      $create_prg = '| gzip --best'
      $extract_prg = "gunzip"
    }
    'none'  : {
      $archive = "${real_import_dir}/sql"
      $create_prg = ''
      $extract_prg = undef
    }
    default : {
      fail("${compression} not supported.")
    }
  }

  $req = unique([Class["oxid::package::packer"] /*,
                                                 * defined(Oxid::Mysql::Execfile["oxid: init database ${db_name}"]) ? {
                                                 * true    => Oxid::Mysql::Execfile["oxid: init database ${db_name}"],
                                                 * default => Class["oxid::package::packer"]
                                                 *}
                                                 */ ])

  if $purge {
    exec { "${name}: purge ${archive}":
      command => "rm -f -r '${archive}'",
      path    => $oxid::params::path,
      unless  => "test -e '${archive}'",
      before  => Exec["mkdir -p '${real_import_dir}'"]
    }
  }

  exec { "${name}: sql mkdir -p '${real_import_dir}'":
    command => "mkdir -p '${real_import_dir}'",
    path    => $oxid::params::path,
    unless  => "test -d '${real_import_dir}'"
  } ->
  file { "${real_import_dir}/${ident_file}.private":
    ensure  => present,
    content => $ssh_ident_content,
    mode    => 0600
  } ->
  exec { "${name}: remote mysqldump ${remote_db_name}":
    command => "ssh ${$option_str} ${name} 'mysqldump --host=\"$remote_db_host\" --port=${remote_db_port} --user=\"$remote_db_user\" --password=\"$remote_db_password\" $dump_options_str \"$remote_db_name\" $dump_tables_str ${create_prg}' > ${archive}",
    path    => $oxid::params::path,
    unless  => "test -f '${archive}'",
    timeout => $timeout,
    require => $req
  } ->
  exec { "rm -f '${real_import_dir}/${ident_file}.private'":
    path   => $oxid::params::path,
    onlyif => "test -f '${real_import_dir}/${ident_file}.private'"
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
    },
    require     => $req
  }
}