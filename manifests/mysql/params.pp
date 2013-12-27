class oxid::mysql::params {
  $default_port = 3306
  $default_host = 'localhost'
  $default_user = 'root'
  $default_db_charset = 'latin1'

  $default_max_connections = 100
  $default_table_cache = $default_max_connections * 128
  $default_key_buffer = inline_template("(@memorysize.split(' ')[0].to_i * 1024) / 4")

  $default_join_buffer_size = inline_template("$default_key_buffer / 32")

  $default_query_cache_size = inline_template("$default_key_buffer / 4")

  $default_query_cache_limit = $default_query_cache_size

  $override_options = {
    'mysqld' => {
      'max_connections'   => $default_max_connections,
      'table_cache'       => $default_table_cache,
      'key_buffer'        => $default_key_buffer,
      'join_buffer_size'  => $default_join_buffer_size,
      'query_cache_size'  => $default_query_cache_size,
      'query_cache_limit' => $default_query_cache_limit
    }
  }
}