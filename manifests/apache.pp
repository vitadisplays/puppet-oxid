include 'stdlib'
  
class oxid::apache($vhosts = undef) {  
  include oxid::stages
  include oxid::apache::params
  
  $vhostnames = keys($vhosts)
  
  class {apache2: }
  
  apache2::module { "php5": package_require => "libapache2-mod-php5" }
  apache2::module { "ssl":  }
  apache2::module { "deflate" :  }
  apache2::module { "headers" :  }
  apache2::module { "expires" :  }
  apache2::module { "rewrite" : }

  apache2::site {
      "000-default": ensure => 'absent';
  } ->
  
  vhost{$vhostnames : vhosts => $vhosts}
  
  define vhost($vhosts) { 
    $config = $vhosts[$name]
        
    file { "site-${$name}":
		    path    => "${oxid::apache::params::apache2_sites}-available/${name}",
		    owner   => root,
		    group   => root,
		    mode    => 644,
		    content => template($config['template'])
		} ->
		  
		 apache2::site {
        $name: ensure => 'present';
     }
   }
}

class oxid::apache2 {
  include oxid::apache::params

   # Define an apache2 site. Place all site configs into
   # /etc/apache2/sites-available and en-/disable them with this type.
   #
   # You can add a custom require (string) if the site depends on packages
   # that aren't part of the default apache2 package. Because of the
   # package dependencies, apache2 will automagically be included.
   define site ( $ensure = 'present' ) {
      case $ensure {
         'present' : {
            exec { "/usr/sbin/a2ensite $name":
               unless => "/bin/readlink -e ${oxid::apache::params::apache2_sites}-enabled/$name",
               notify => Exec["reload-apache2"],
               require => Package['apache2'],
            }
         }
         'absent' : {
            exec { "/usr/sbin/a2dissite $name":
               onlyif => "/bin/readlink -e ${oxid::apache::params::apache2_sites}-enabled/$name",
               notify => Exec["reload-apache2"],
               require => Package["apache2"],
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
   define module ( $ensure = 'present', $package_require = 'apache2' ) {
      case $ensure {
         'present' : {
            exec { "/usr/sbin/a2enmod $name":
               unless => "/bin/readlink -e ${oxid::apache::params::apache2_mods}-enabled/${name}.load",
               notify => Exec["force-reload-apache2"],
               require => Package[$package_require],
            }            
         }
         'absent': {
            exec { "/usr/sbin/a2dismod $name":
               onlyif => "/bin/readlink -e ${oxid::apache::params::apache2_mods}-enabled/${name}.load",
               notify => Exec["force-reload-apache2"],
               require => Package["apache2"],
            }
         }
         default: { err ( "Unknown ensure value: '$ensure'" ) }
      }      
   }
   
   package { $oxid::apache::params::packages: ensure => installed } 
   
   # Notify this when apache needs a reload. This is only needed when
   # sites are added or removed, since a full restart then would be
   # a waste of time. When the module-config changes, a force-reload is
   # needed.
   exec { "reload-apache2":
      command => "/etc/init.d/apache2 reload",
      refreshonly => true,
   }

   exec { "force-reload-apache2":
              command => "/etc/init.d/apache2 force-reload",
              refreshonly => true,
   }

   # We want to make sure that Apache2 is running.
   service { "apache2":
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      require => Package["apache2"],
   }
}