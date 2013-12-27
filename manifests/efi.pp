define oxid::efiRemover (
  $db,
  $host = $oxid::mysql::params::default_host,
  $port = $oxid::mysql::params::default_port,
  $user = $oxid::mysql::params::default_user,
  $password) {
  $tables_to_drop = ["efi_paypal_transaction_drop"]

}