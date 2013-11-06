include 'stdlib'
  
class oxid::apache2($mods_enabled = undef, $sites_enabled = undef,$mods_disabled = undef, $sites_disabled = undef) {
  include oxid::apache2::params

   # Define an apache2 site. Place all site configs into
   # /etc/apache2/sites-available and en-/disable them with this type.
   #
   # You can add a custom require (string) if the site depends on packages
   # that aren't part of the default apache2 package. Because of the
   # package dependencies, apache2 will automagically be included.
   define site ( $ensure = 'present' ) {
      case $ensure {
         'present' : {
            exec { "a2ensite $name":
               unless => "readlink -e ${oxid::apache2::params::sites_path}-enabled/$name",
               notify => Exec["reload-httpd-server"],
               require => Package['httpd-server'],
               path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
            }
         }
         'absent' : {
            exec { "a2dissite $name":
               onlyif => "readlink -e ${oxid::apache2::params::sites_path}-enabled/$name",
               notify => Exec["reload-httpd-server"],
               require => Package["httpd-server"],
               path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
            }
         }
         default: { err ( "Unknown ensure value: '$ensure'" ) }
      }
   }

   # Define an apache2 module. Debian packages place the module config
   # into /etc/apache2/mods-available.
   #
   # You can add a custom require (string) if the module depends on 
   # packages that aren't part of the default apache2 package. Because of 
   # the package dependencies, apache2 will automagically be included.
   define mod ( $ensure = 'present', $package_require = 'httpd-server' ) {
      case $ensure {
         'present' : {
            exec { "a2enmod $name":
               unless => "readlink -e ${oxid::apache2::params::mods_path}-enabled/${name}.load",
               notify => Exec["force-reload-httpd-server"],
               require => Package[$package_require],
               path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
            }            
         }
         'absent': {
            exec { "a2dismod $name":
               onlyif => "readlink -e ${oxid::apache2::params::mods_path}-enabled/${name}.load",
               notify => Exec["force-reload-httpd-server"],
               require => Package["httpd-server"],
               path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
            }
         }
         default: { err ( "Unknown ensure value: '$ensure'" ) }
      }      
   }
   
   define zend_guard_loader_install($ensure = "present", $confd_dir = "/etc/php5/apache2/conf.d", $extension_dir = "/usr/local/zend/lib") {
    $module_path = get_module_path('oxid')
    
    if $ensure == "present" {
      exec {"${name}-make-extension-path":
        command => "mkdir -p ${extension_dir}/loader/php-5.3.x && chown root:root ${extension_dir}/loader/php-5.3.x",
        path   => "/usr/bin:/usr/sbin:/bin",  
        unless => "test -d ${extension_dir}/loader/php-5.3.x"
      } ->
      
      file { "${extension_dir}/loader/php-5.3.x/ZendGuardLoader.so":
        owner   => "root",
        group   => "root",
        source  => "${module_path}/files/zend-guard-loader/php-5.3.x/ZendGuardLoader.so",
        ensure => "present"
      } ->
    
      file { "${$confd_dir}/zend-guard-loader.ini":
        owner   => "root",
        group   => "root",
        content  => template("oxid/apache2/zend-guard-loader.erb"),
        notify => Exec["force-reload-httpd-server"]
      }
    } elsif $ensure == "absent" {
      file { "${extension_dir}/loader/php-5.3.x/ZendGuardLoader.so":
        ensure => "absent"
      } ->
      
      file { "${$confd_dir}/zend-guard-loader.ini":
        ensure => "absent",
        notify => Exec["force-reload-httpd-server"]
      }
    } else {
      fail("ensure ${ensure} unkown.")
    }
  }
  
  define vhost($vhosts) { 
    $config = $vhosts[$name]
        
    file { "site-${$name}":
        path    => "${oxid::apache2::params::sites_path}-available/${name}",
        owner   => root,
        group   => root,
        mode    => 644,
        content => template($config['template']),
        require => Package["httpd-server"]
    } ->
      
     site {
        $name: ensure => 'present';
     }
  } 
   
  define pear () {
    exec { "pear install ${name}":
      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
      unless  => "pear info ${name}",
      notify  => Exec["force-reload-apache2"],
      require => Package['php-pear']
    }
  }
  
  $vhostnames = keys($sites_enabled)
  
  package { "httpd-server": 
    name => 'apache2',
    ensure => installed
  } ->
  
  package { $oxid::apache2::params::packages: 
    ensure => installed 
  } -> 
   
   # Notify this when apache needs a reload. This is only needed when
   # sites are added or removed, since a full restart then would be
   # a waste of time. When the module-config changes, a force-reload is
   # needed.
   exec { "reload-httpd-server":
      command => "/etc/init.d/apache2 reload",
      refreshonly => true,
   }

   exec { "force-reload-httpd-server":
              command => "/etc/init.d/apache2 force-reload",
              refreshonly => true,
   }

   # We want to make sure that Apache2 is running.
   service { "httpd-server":
      name => "apache2",
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      require => Package["httpd-server"]
   }
   
   # Zend Guar Loader install
   zend_guard_loader_install{"zend-guard-loader-install":} ->
   
   mod{'php5': package_require => 'libapache2-mod-php5'}
   
   if $mods_enabled != undef {
      mod{$mods_enabled : }
   }
   
   if $mods_disabled != undef {
      mod{$mods_disabled : ensure => "absent"}
   }
   
   if $sites_disabled != undef {
     site{$sites_disabled : ensure => "absent"}
   }
   
   if $sites_enabled != undef {
     vhost{$vhostnames : vhosts => $sites_enabled}
   }    
}