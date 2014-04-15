class oxid::package::packer {
  if !defined(Class[oxid::apt]) {
    include oxid::apt
  }

  if !defined(Package["unzip"]) {
    package { "unzip":
      ensure  => installed
    }
  }

  if !defined(Package["bzip2"]) {
    package { "bzip2":
      ensure  => installed
    }
  }

  if !defined(Package["zip"]) {
    package { "zip":
      ensure  => installed
    }
  }

  if !defined(Package["unzip"]) {
    package { "unzip":
      ensure  => installed
    }
  }
  
    if !defined(Package["unrar-free"]) {
    package { "unrar-free":
      ensure  => installed
    }
  }
}