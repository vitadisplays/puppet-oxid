class oxid::mysql::server::params {
  $max_connections = 100
  $table_cache = $max_connections * 128

  $key_buffer = inline_template("<%= ((@memorysize.split(' ')[0].to_i * 1024) / 4).floor -%>")

  $join_buffer_size = inline_template("<%= (@key_buffer.to_i / 32).floor -%>") 

  $query_cache_size = inline_template("<%= (@key_buffer.to_i / 4).floor -%>") 
  $query_cache_limit = $query_cache_size

  $override_options = {
    'mysqld' => {
      'character-set-server'  => $oxid::mysql::params::default_db_charset,
      'collation-server'  => $oxid::mysql::params::default_db_collation,
      'max_connections'   => $max_connections,
      'table_cache'       => $table_cache,
      'key_buffer'        => "${key_buffer}M",
      'join_buffer_size'  => "${join_buffer_size}M",
      'query_cache_size'  => "${query_cache_size}M",
      'query_cache_limit' => "${query_cache_limit}M"
    }
  }
}