define oxid::repository::file ($configuration, $source) {
  case $source {
    /^puppet:\/\/(.*)/ : {
      $file = $1
      $repo_file = inline_template("<%= File.join(@configuration['directory'], @file) %>")

      if !defined(File[$repo_file]) {
        file { $repo_file:
          ensure => present,
          source => $source
        }
      }
    }

    default            : {
      $repo_file = inline_template("<%= File.join(@configuration['directory'], @source) %>")

      if !defined(File[$repo_file]) {
        file { $repo_file:
          ensure => present
        }
      }
    }
  }
}