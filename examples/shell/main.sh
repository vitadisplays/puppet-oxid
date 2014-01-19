#!/bin/sh
	
# Directory in which librarian-puppet should manage its modules directory
PUPPET_DIR=/opt/puppet/share/puppet

if [ ! -d $PUPPET_DIR ]; then
	mkdir -p $PUPPET_DIR
	chmod 775 $PUPPET_DIR
fi

cat <<'EOF' > $PUPPET_DIR/Puppetfile
mod 'oxid', :git => 'https://github.com/vitadisplays/puppet-oxid.git'
EOF

# NB: librarian-puppet might need git installed. If it is not already installed
# in your basebox, this will manually install it at this point using apt or yum
GIT=/usr/bin/git
APT_GET=/usr/bin/apt-get

# apt update and ruby and gem 1.9.1 installation.
if [ -x $APT_GET ]; then
     apt-get -q -y update
     
     apt-get -q -y install ruby1.9.1 ruby1.9.1-dev rubygems1.9.1 irb1.9.1 ri1.9.1 rdoc1.9.1 build-essential libopenssl-ruby1.9.1 libssl-dev zlib1g-dev libaugeas-ruby1.9.1
     update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby1.9.1 400 --slave   /usr/share/man/man1/ruby.1.gz ruby.1.gz  /usr/share/man/man1/ruby1.9.1.1.gz --slave /usr/bin/ri ri /usr/bin/ri1.9.1 --slave /usr/bin/irb irb /usr/bin/irb1.9.1 --slave /usr/bin/rdoc rdoc /usr/bin/rdoc1.9.1
     update-alternatives --config ruby
     update-alternatives --config gem
else
	 echo "No package installer available. You may need to install ruby and gem manually."    
fi

# git installation. 
if [ ! -x $GIT ]; then
    if [ -x $APT_GET ]; then
        apt-get -q -y install git
    else
        echo "No package installer available. You may need to install git manually."        
        exit -1
    fi
fi

if [ `gem query --local | grep "^open3_backport (0.0.3)$" | wc -l` -eq 0 ]; then
	gem install --no-rdoc --no-ri --version '>= 0.0.3' open3_backport
fi

if [ `gem query --local | grep -e "^facter (1.7.4)$" | wc -l` -eq 0 ]; then
	gem install --no-rdoc --no-ri --version '>= 1.7.4' facter
fi

if [ `gem query --local | grep -e "^puppet (3.4.2)$"| wc -l` -eq 0 ]; then
	gem install --no-rdoc --no-ri --version '>= 3.4.2' puppet
fi

if [ `gem query --local | grep librarian-puppet-maestrodev | wc -l` -eq 0 ]; then  
  gem install --no-rdoc --no-ri librarian-puppet-maestrodev
  cd $PUPPET_DIR && librarian-puppet install --clean --verbose
else
  cd $PUPPET_DIR && librarian-puppet update --verbose
fi