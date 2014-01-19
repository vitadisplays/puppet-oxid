class oxid::package::utils {
  if !defined(Class[oxid::apt]) {
    include oxid::apt
  }

  if !defined(Package["perl"]) {
    package { "perl":
      ensure  => installed,
      require => Class[oxid::apt]
    }
  }

  if !defined(Package["rssh"]) {
    package { "rssh":
      ensure  => installed,
      require => Class[oxid::apt]
    }
  }

  if !defined(Package["rsync"]) {
    package { "rsync":
      ensure  => installed,
      require => Class[oxid::apt]
    }
  }
}