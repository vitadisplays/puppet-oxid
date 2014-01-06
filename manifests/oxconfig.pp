# Define: oxid::oxconfig
#
# This define configured shop parameters using oxxonfig class.
#
# This used a php script, using bootstrap.php, in the shop directory to run.
# Configuration parameter will be converted to a json string. That will be used in the script.
#
# Parameters:
#
#   - ensure              present or absen. Default is present.
#   - shopid              Shop id, Used for Enterprise Editions. Default is oxbase.
#   - type                default for common parameters, theme for theme parameters and module for module parameters
#   - module              empty for common parameters and theme or module id.
#   - shop_dir            The oxid shop directroy.
#   - configurations      Hash value.
#
# Structure:
#  {
#    'confbools' => {                           Boolean values
#      'testbool'  => true,                     Key/Value pairs
#      'Otherbool' => false                            
#    }
#    ,
#    'confstrs'  => {                           String values
#      'teststr'   => "test"                    Key/Value pairs
#    }
#    ,
#    'confarrs'  => {                           Array values
#      'testarr'   => ["1", "2"]                Key/Value pairs
#    }
#    ,
#    'confaarrs' => {
#      'testaarr'  => {                         Hash values
#        "hash"         => {"a" => "b"}         Key/Value pairs
#      }
#    }
#    ,
#    'confnum'   => {                           Numeric values
#      'testnum'   => 1                         Key/Value pairs
#    }
#  }
#
# You have not to define all parent keys for using this define.
#
# Actions:
#   - Configure 
#
# Requires:
#   - Repository
#   - Apache instance
#   - MySQL Server instance
#   - PHP
#   - Configured oxid shop
#
# Sample Usage:
#    oxid::oxconfig {'bl_rssNewest':
#      shopid  => 1,
#      shop_dir => "/srv/www/oxid",
#      configurations =>  {
#        'confbools'     => {
#          'bl_rssNewest' => false
#       }
#     }
#   }
define oxid::oxconfig (
  $shop_dir = $oxid::params::shop_dir,
  $shopid   = $oxid::params::default_shopid,
  $module   = '',
  $type     = 'default',
  $ensure   = "present",
  $configurations) {
  $test = {
    'confbools' => {
      'testbool'  => true
    }
    ,
    'confstrs'  => {
      'teststr'   => "test"
    }
    ,
    'confarrs'  => {
      'testarr'   => ["1", "2"]
    }
    ,
    'confaarrs' => {
      'testaarr'  => {
        "a"         => "b"
      }
    }
    ,
    'confnum'   => {
      'testnum'   => 1
    }
  }

  validate_absolute_path($shop_dir)
  validate_string($module)
  validate_re($ensure, ["^present$", "^absent$"])
  validate_re($type, ["^default$", "^module$", "^theme$"])
  validate_hash($configurations)

  $php_file = inline_template("<%= File.join(@shop_dir, (0...32).map{ ('a'..'z').to_a[rand(26)] }.join + '_config.php') %>")
  $json_configurations = inline_template('<%= require "json"; JSON.generate @configurations %>')

  file { $php_file:
    ensure  => 'present',
    mode    => "0755",
    content => template("oxid/oxid/php/config.erb")
  } ->
  oxid::php::runner { $php_file: source => $php_file, } ->
  exec { "rm -f '${php_file}'": path => $oxid::params::path }
}