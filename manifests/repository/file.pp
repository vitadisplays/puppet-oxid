define oxid::repository::file ($configuration, $source) {
  $repo_file = inline_template("<%= File.join(@configuration['directory'], @source) %>")

  if !defined(File[$repo_file]) {
    file { $repo_file:
      ensure => present,
      source => $source
    }
  }

  /* $ext = inline_template("<%= File.extname(@real_file) %>")
   *
   * if count(grep($oxid::params::supported_archives, $ext)) > 0 {
   * if $unpack {
   * oxid::unpack { $real_file:
   *   destination   => $destination
   *}
   *}
   * } else {
   * exec { "cp -r -f '${real_file}' '${destination}'": path => $oxid::params::path }
   *}
   */
}