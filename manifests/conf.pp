define oxid::conf (
  $source             = undef,
  $content            = undef,
  $shop_dir           = $oxid::params::shop_dir,
  $compile_dir        = $oxid::params::compile_dir,
  $db_type            = $oxid::params::db_type,
  $db_host            = $oxid::params::db_host,
  $db_name            = $oxid::params::db_name,
  $db_user            = $oxid::params::db_user,
  $db_password        = $oxid::params::db_password,
  $shop_url           = $oxid::params::shop_url,
  $shop_ssl_url       = $oxid::params::shop_ssl_url,
  $admin_ssl_url      = $oxid::params::admin_ssl_url,
  $utf8_mode          = $oxid::params::utf8_mode,
  $extra_replacements = {
  }
) {
  $mycompile_dir = $compile_dir ? {
    undef   => "${shop_dir}/tmp",
    default => $compile_dir
  }

  if $source != undef or $content != undef {
    file { "${shop_dir}/config.inc.php_${name}":
      ensure  => present,
      source  => $source,
      content => $content
    } -> exec { "mv -f '${shop_dir}/config.inc.php_${name}' '${shop_dir}/config.inc.php'":
      path   => $oxid::params::path,
      notify => defined(Oxid::FileCheck[$name]) ? {
        true    => Oxid::FileCheck[$name],
        default => undef
      }
    }
  } else {
    oxid::configureConfig { $name:
      shop_dir      => $shop_dir,
      compile_dir   => $mycompile_dir,
      db_type       => $db_type,
      db_host       => $db_host,
      db_name       => $db_name,
      db_user       => $db_user,
      db_password   => $db_password,
      shop_url      => $shop_url,
      shop_ssl_url  => $shop_ssl_url,
      admin_ssl_url => $admin_ssl_url,
      utf8_mode     => $utf8_mode,
      notify        => defined(Oxid::FileCheck[$name]) ? {
        true    => Oxid::FileCheck[$name],
        default => undef
      }
    }
  }
}

define oxid::htaccess (
  $shop_dir           = $oxid::params::shop_dir,
  $source             = undef,
  $content            = undef,
  $rewrite_base       = $oxid::params::rewrite_base,
  $extra_replacements = {
  }
) {
  if $source != undef or $content != undef {
    file { "${shop_dir}/.htaccess_${name}":
      ensure  => present,
      source  => $source,
      content => $content
    } -> exec { "mv -f '${shop_dir}/.htaccess_${name}' '${shop_dir}/.htaccess'":
      path   => $oxid::params::path,
      notify => defined(Oxid::FileCheck[$name]) ? {
        true    => Oxid::FileCheck[$name],
        default => undef
      }
    }
  } else {
    oxid::configureHtaccess { $name:
      shop_dir           => $shop_dir,
      rewrite_base       => $rewrite_base,
      extra_replacements => $extra_replacements,
      notify             => defined(Oxid::FileCheck[$name]) ? {
        true    => Oxid::FileCheck[$name],
        default => undef
      }
    }
  }
}

define oxid::configureConfig (
  $shop_dir           = $oxid::params::shop_dir,
  $compile_dir        = $oxid::params::compile_dir,
  $db_type            = $oxid::params::db_type,
  $db_host            = $oxid::params::db_host,
  $db_name            = $oxid::params::db_name,
  $db_user            = $oxid::params::db_user,
  $db_password        = $oxid::params::db_password,
  $shop_url           = $oxid::params::shop_url,
  $shop_ssl_url       = $oxid::params::shop_ssl_url,
  $admin_ssl_url      = $oxid::params::admin_ssl_url,
  $utf8_mode          = $oxid::params::utf8_mode,
  $mysql_user         = $oxid::params::mysql_user,
  $extra_replacements = {
  }
) {
  validate_string($db_type)
  validate_string($db_host)
  validate_string($db_name)
  validate_string($db_user)
  validate_string($db_password)
  validate_string($shop_url)

  validate_absolute_path($shop_dir)
  validate_absolute_path($compile_dir)
  validate_re($utf8_mode, "[0-9]*")

  validate_hash($extra_replacements)

  $replace_tokens = merge({
    "\$this->dbType[ ]*=[ ]*.*;"       => $db_type ? {
      undef   => "\$this->dbType = null;",
      default => "\$this->dbType= '${db_type}';"
    },
    "\$this->dbHost[ ]*=[ ]*.*;"       => $db_host ? {
      undef   => "\$this->dbHost = null;",
      default => "\$this->dbHost = '${db_host}';"
    },
    "\$this->dbName[ ]*=[ ]*.*;"       => $db_name ? {
      undef   => "\$this->dbName = null;",
      default => "\$this->dbName = '${db_name}';"
    },
    "\$this->dbUser[ ]*=[ ]*.*;"       => $db_user ? {
      undef   => "\$this->dbUser = null;",
      default => "\$this->dbUser = '${db_user}';"
    },
    "\$this->dbPwd[ ]*=[ ]*.*;"        => $db_password ? {
      undef   => "\$this->dbPwd = null;",
      default => "\$this->dbPwd = '${db_password}';"
    },
    "\$this->sShopURL[ ]*=[ ]*.*;"     => $shop_url ? {
      undef   => "\$this->sShopURL = null;",
      default => "\$this->sShopURL = '${shop_url}';"
    },
    "\$this->sSSLShopURL[ ]*=[ ]*.*;"  => $shop_ssl_url ? {
      undef   => "\$this->sSSLShopURL = null;",
      default => "\$this->sSSLShopURL = '${shop_ssl_url}';"
    },
    "\$this->sAdminSSLURL[ ]*=[ ]*.*;" => $admin_ssl_url ? {
      undef   => "\$this->sAdminSSLURL = null;",
      default => "\$this->sAdminSSLURL = '${admin_ssl_url}';"
    },
    "\$this->sShopDir[ ]*=[ ]*.*;"     => $shop_dir ? {
      undef   => "\$this->sShopDir = null;",
      default => "\$this->sShopDir = '${shop_dir}';"
    },
    "\$this->sCompileDir[ ]*=[ ]*.*;"  => $compile_dir ? {
      undef   => "\$this->sCompileDir = null;",
      default => "\$this->sCompileDir = '${compile_dir}';"
    },
    "\$this->iUtfMode[ ]*=[ ]*.*;"     => $utf8_mode ? {
      undef   => "\$this->iUtfMode = null;",
      default => "\$this->iUtfMode = '${utf8_mode}';"
    } }
  , $extra_replacements)

  replace_all { "${name}: configure ${shop_dir}/config.inc.php":
    file         => "${shop_dir}/config.inc.php",
    replacements => $replace_tokens
  }
}

define oxid::configureHtaccess (
  $shop_dir           = $oxid::params::shop_dir,
  $rewrite_base       = $oxid::params::rewrite_base,
  $extra_replacements = {
  }
) {
  validate_string($rewrite_base)
  validate_absolute_path($shop_dir)
  validate_hash($extra_replacements)

  $replace_tokens = merge({
    "RewriteBase.*" => "RewriteBase ${rewrite_base}"
  }
  , $extra_replacements)

  replace_all { "${name}: configure ${shop_dir}/.htaccess":
    file         => "${shop_dir}/.htaccess",
    replacements => $replace_tokens
  }
}