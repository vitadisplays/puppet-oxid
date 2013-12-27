class oxid::php::params {
  $ensure = 'installed'
  $package = 'libapache2-mod-php5'
  $provider = undef
  $inifile = '/etc/php5/apache2/php.ini'
  $confdir = "/etc/php5/apache2/conf.d"
  $settings = {
    set => {
      'PHP/short_open_tag'      => 'Off',
      'PHP/asp_tags'            => 'Off',
      'PHP/expose_php'          => 'Off',
      'PHP/memory_limit'        => '128M',
      'PHP/display_errors'      => 'Off',
      'PHP/log_errors'          => 'On',
      'PHP/post_max_size'       => '500M',
      'PHP/upload_max_filesize' => '500M',
      'PHP/max_execution_time'  => 600,
      'PHP/allow_url_include'   => 'Off',
      'PHP/allow_url_fopen'     => 'On',
      'PHP/register_globals'    => 'Off',
      'PHP/error_log'           => 'syslog',
      'PHP/output_buffering'    => 4096,
      'PHP/output_handler'      => 'Off',
      'PHP/session.auto_start'  => 'Off',
      'Date/date.timezone'      => 'UTC'
    }
  }
}