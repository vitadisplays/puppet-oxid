define oxid::unpack ($destination, $source = undef, $timeout = 0, $unless = undef) {
  if !defined(Class[oxid::package::packer]) {
    include oxid::package::packer
  }  
  
  $module_path = get_module_path('oxid')
  $unpack_source = $source ? {
    undef   => $name,
    default => $source
  }
  validate_absolute_path($destination, $unpack_source)
  
  case $unpack_source {
    /^(.*\.phar$)/   : {
      exec { "unphar ${unpack_source} to ${destination}":
        command => "php -f ${module_path}/functions/oxid/phar-extract.php '$1' '${destination}'",
        path    => $oxid::params::path,
        unless  => $unless,
        timeout => $timeout,
        require => Class[oxid::package::packer]
      }
    }
    /^(.*\.zip$)/    : {
      exec { "unzip ${unpack_source} to ${destination}":
        command => "unzip -d '${destination}' -o --qq '$1'",
        path    => $oxid::params::path,
        unless  => $unless,
        timeout => $timeout,
        require => Class[oxid::package::packer]
      }
    }
    /^(.*\.tar\.gz|.*\.tgz$)/ : {
      exec { "untar/gz ${unpack_source} to ${destination}":
        command => "tar -C '${destination}' -zxf '$1'",
        path    => $oxid::params::path,
        unless  => $unless,
        timeout => $timeout,
        require => Class[oxid::package::packer]
      }
    }
    /^(.*\.tar\.bz2$)/ : {
      exec { "untar/gz ${unpack_source} to ${destination}":
        command => "tar -C '${destination}' -jxf '$1'",
        path    => $oxid::params::path,
        unless  => $unless,
        timeout => $timeout,
        require => Class[oxid::package::packer]
      }
    }    
    /^(.*\.gz$)/     : {
      $filename = inline_template("<%= File.basename(@unpack_source).chomp('.gz') %>")

      exec { "gunzip ${unpack_source} to ${destination}":
        command => "gunzip -c '$1' > '${destination}/${filename}'",
        path    => $oxid::params::path,
        unless  => $unless,
        timeout => $timeout,
        require => Class[oxid::package::packer]
      }
    }
    /^(.*\.bz2$)/     : {
      $filename = inline_template("<%= File.basename(@unpack_source).chomp('.gz') %>")

      exec { "bunzip2 ${unpack_source} to ${destination}":
        command => "bunzip2 -c '$1' > '${destination}/${filename}'",
        path    => $oxid::params::path,
        unless  => $unless,
        timeout => $timeout,
        require => Class[oxid::package::packer]
      }
    }
    default          : {
      fail("Unrecognized schema: ${unpack_source}")
    }
  }
}

define oxid::unpackModul ($shop_dir, $source = undef, $timeout = 0) {

}

define oxid::unpackTheme ($shop_dir, $source = undef, $timeout = 0) {

}