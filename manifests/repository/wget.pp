include oxid::params
include wget

define oxid::repository::wget ($configuration, $source) {
  if is_hash($source) {
    $keys = keys($source)

    if (count($keys) != 1) {
      fail("Only one Key/Value Pair allowed.")
    }

    $mysource = $keys[0]
    $_mytarget = $source[$mysource]
    $target = inline_template("<%= File.join(@directory, File.basename(@_mytarget)) %>")
  } else {
    $mysource = $source
    $target = inline_template("<%= File.join(@directory, File.basename(@source)) %>")
  }

  $real_url = join([$configuration['url'], $mysource], '/')

  wget::fetch { $real_url:
    destination => $target,
    user        => $configuration['user'],
    password    => $configuration['password'],
    timeout     => $configuration['timeout'],
    verbose     => $configuration['verbose'],
    redownload  => $configuration['redownload']
  }

  /* if $destination != undef {
   * oxid::unpack { $dest_path:
   * destination => $destination,
   * require     => Wget::Fetch[$real_url]
   *}
   *}
   */
  /* } else {
   * $supported_archives_str = join($oxid::params::supported_archives, ',')
   * fail("Only archives with extension ${supported_archives_str} are supported, but ${source} with extension ${ext} found.")
   *}
   */
}