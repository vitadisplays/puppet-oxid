define oxid::updateViews ($shop_dir = $oxid::params::shop_dir, $refreshonly = false) {
  $php_file = inline_template("<%= File.join(@shop_dir, (0...32).map{ ('a'..'z').to_a[rand(26)] }.join + '_updateviews.php') %>")

  file { $php_file:
    ensure  => 'present',
    mode    => "0755",
    content => template("oxid/oxid/php/update-views.erb")
  } ->
  oxid::php::runner { $php_file:
    source      => $php_file,
    refreshonly => $refreshonly
  } ->
  exec { "rm -f '${php_file}'":
    path        => $oxid::params::path,
    refreshonly => $refreshonly
  }
}