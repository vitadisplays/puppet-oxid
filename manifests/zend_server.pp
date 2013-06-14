class oxid::zend_server($shop_dir, $mods, $sites) {
    include oxid::zend_server::params
    include oxid::stages
    
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
               unless => "readlink -e ${oxid::zend_server::params::sites_path}-enabled/$name",
               notify => Service["httpd-server"],
               require => Package['httpd-server'],
               path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
            }
         }
         'absent' : {
            exec { "a2dissite $name":
               onlyif => "readlink -e ${oxid::zend_server::params::sites_path}-enabled/$name",
               notify => Service["httpd-server"],
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
   define mod ( $ensure = 'present', $package_require = 'zend-server-php-5.3' ) {
      case $ensure {
         'present' : {
            exec { "a2enmod $name":
               unless => "readlink -e ${oxid::zend_server::params::mods_path}-enabled/${name}.load",
               notify => Service["httpd-server"],
               require => Package[$package_require],
               path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
            }            
         }
         'absent': {
            exec { "a2dismod $name":
               onlyif => "readlink -e ${oxid::zend_server::params::mods_path}-enabled/${name}.load",
               notify => Service["httpd-server"],
               require => Package[$package_require],
               path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin"
            }
         }
         default: { err ( "Unknown ensure value: '$ensure'" ) }
      }      
   }
   
   define vhost($vhosts) { 
    $config = $vhosts[$name]
        
    file { "site-${$name}":
        path    => "${oxid::zend_server::params::sites_path}-available/${name}",
        owner   => root,
        group   => root,
        mode    => 644,
        content => template($config['template'])
    } ->
      
     site {
        $name: ensure => 'present';
     }
  } 
   
  define pear () {
    exec { "pear install ${name}":
      path    => "/usr/bin:/usr/sbin:/bin:/usr/local/zend/bin",
      unless  => "pear info ${name}",
      notify => Service["httpd-server"],
      require => Package['zend-server-php-5.3']
    }
  }
  
  define zend_guard_loader_install($ensure = "present", $confd_dir = "/usr/local/zend/etc/conf.d") {
    $module_path = get_module_path('oxid')
    
    if $ensure == "present" {
      package {'php-5.3-loader-zend-server': ensure => "present", require => Package['zend-server-php-5.3'] } ->
      
      file { "${$confd_dir}/loader.ini":
        owner   => "zend",
        group   => "zend",
        content  => template("${module_path}/templates/zend_server/zend-guard-loader.erb"),
        notify => Service["httpd-server"],
        require => Package['zend-server-php-5.3']
      }
    } elsif $ensure == "absent" {
      file { "${$confd_dir}/loader.ini":
        ensure => "absent",
        notify => Service["httpd-server"]
      }
    } else {
      fail("ensure ${ensure} unkown.")
    }
  }
  
  $vhostnames = keys($sites)
   
  apt::key { "zend":
	  key_source => "http://repos.zend.com/zend.key",
	} ->
	
	apt::source { "zend-server":
	  location          => "http://repos.zend.com/zend-server/6.0/deb_ssl1.0",
	  release           => "server",
	  repos             => "non-free",
	  include_src       => false
	} -> 
  
  package  {"httpd-server":
    name => "zend-server-php-5.3",     
    ensure => installed
  } ->
  
  package  { $oxid::zend_server::params::packages:    
    ensure => installed
  }
  
   # We want to make sure that Apache2 is running.
   service { "httpd-server":
      name => "zend-server",
      ensure => running,
      hasstatus => true,
      hasrestart => true,
      require => Package["httpd-server"],
      provider => "init"
   }
   
   zend_guard_loader_install{"zend-guard-loader-install":} ->
   
   mod{$mods:} ->
   
   site {
      "000-default": ensure => 'absent';
   } ->
   
   vhost{$vhostnames : vhosts => $sites}
   
   class {
    oxid::zend_server::debug: 
    shop_dir => $shop_dir,
    stage => last;    
  }
}

class oxid::zend_server::debug($shop_dir) {
  file { "${shop_dir}/dummy.php":
    ensure => 'link',
    target => '/usr/local/zend/share/dist/dummy.php'
   }
}